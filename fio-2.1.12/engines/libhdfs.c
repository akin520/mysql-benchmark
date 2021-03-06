/*
 * libhdfs engine
 *
 * this engine helps perform read/write operations on hdfs cluster using
 * libhdfs. hdfs doesnot support modification of data once file is created.
 *
 * so to mimic that create many files of small size (e.g 256k), and this
 * engine select a file based on the offset generated by fio.
 *
 * thus, random reads and writes can also be achieved with this logic.
 *
 * NOTE: please set environment variables FIO_HDFS_BS and FIO_HDFS_FCOUNT
 * to appropriate value to work this engine properly
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/uio.h>
#include <errno.h>
#include <assert.h>

#include "../fio.h"

#include "hdfs.h"

struct hdfsio_data {
	char host[256];
	int port;
	hdfsFS fs;
	hdfsFile fp;
	unsigned long fsbs;
	unsigned long fscount;
	unsigned long curr_file_id;
	unsigned int numjobs;
	unsigned int fid_correction;
};

static int fio_hdfsio_setup_fs_params(struct hdfsio_data *hd)
{
	/* make sure that hdfsConnect is invoked before executing this function */
	hdfsSetWorkingDirectory(hd->fs, "/.perftest");
	hd->fp = hdfsOpenFile(hd->fs, ".fcount", O_RDONLY, 0, 0, 0);
	if (hd->fp) {
		hdfsRead(hd->fs, hd->fp, &(hd->fscount), sizeof(hd->fscount));
		hdfsCloseFile(hd->fs, hd->fp);
	}
	hd->fp = hdfsOpenFile(hd->fs, ".fbs", O_RDONLY, 0, 0, 0);
	if (hd->fp) {
		hdfsRead(hd->fs, hd->fp, &(hd->fsbs), sizeof(hd->fsbs));
		hdfsCloseFile(hd->fs, hd->fp);
	}

	return 0;
}

static int fio_hdfsio_prep(struct thread_data *td, struct io_u *io_u)
{
	struct hdfsio_data *hd;
	hdfsFileInfo *fi;
	unsigned long f_id;
	char fname[80];
	int open_flags = 0;

	hd = td->io_ops->data;

	if (hd->curr_file_id == -1) {
		/* see comment in fio_hdfsio_setup() function */
		fio_hdfsio_setup_fs_params(hd);
	}

	/* find out file id based on the offset generated by fio */
	f_id = (io_u->offset / hd->fsbs) + hd->fid_correction;

	if (f_id == hd->curr_file_id) {
		/* file is already open */
		return 0;
	}

	if (hd->curr_file_id != -1) {
		hdfsCloseFile(hd->fs, hd->fp);
	}

	if (io_u->ddir == DDIR_READ) {
		open_flags = O_RDONLY;
	} else if (io_u->ddir == DDIR_WRITE) {
		open_flags = O_WRONLY;
	} else {
		printf("Invalid I/O Operation\n");
	}

	hd->curr_file_id = f_id;
	do {
		sprintf(fname, ".f%lu", f_id);
		fi = hdfsGetPathInfo(hd->fs, fname);
		if (fi->mSize >= hd->fsbs || io_u->ddir == DDIR_WRITE) {
			/* file has enough data to read OR file is opened in write mode */
			hd->fp =
			    hdfsOpenFile(hd->fs, fname, open_flags, 0, 0,
					 hd->fsbs);
			if (hd->fp) {
				break;
			}
		}
		/* file is empty, so try next file for reading */
		f_id = (f_id + 1) % hd->fscount;
	} while (1);

	return 0;
}

static int fio_io_end(struct thread_data *td, struct io_u *io_u, int ret)
{
	if (ret != (int)io_u->xfer_buflen) {
		if (ret >= 0) {
			io_u->resid = io_u->xfer_buflen - ret;
			io_u->error = 0;
			return FIO_Q_COMPLETED;
		} else
			io_u->error = errno;
	}

	if (io_u->error)
		td_verror(td, io_u->error, "xfer");

	return FIO_Q_COMPLETED;
}

static int fio_hdfsio_queue(struct thread_data *td, struct io_u *io_u)
{
	struct hdfsio_data *hd;
	int ret = 0;

	hd = td->io_ops->data;

	if (io_u->ddir == DDIR_READ) {
		ret =
		    hdfsRead(hd->fs, hd->fp, io_u->xfer_buf, io_u->xfer_buflen);
	} else if (io_u->ddir == DDIR_WRITE) {
		ret =
		    hdfsWrite(hd->fs, hd->fp, io_u->xfer_buf,
			      io_u->xfer_buflen);
	} else {
		printf("Invalid I/O Operation\n");
	}

	return fio_io_end(td, io_u, ret);
}

int fio_hdfsio_open_file(struct thread_data *td, struct fio_file *f)
{
	struct hdfsio_data *hd;

	hd = td->io_ops->data;
	hd->fs = hdfsConnect(hd->host, hd->port);
	hdfsSetWorkingDirectory(hd->fs, "/.perftest");
	hd->fid_correction = (getpid() % hd->numjobs);

	return 0;
}

int fio_hdfsio_close_file(struct thread_data *td, struct fio_file *f)
{
	struct hdfsio_data *hd;

	hd = td->io_ops->data;
	hdfsDisconnect(hd->fs);

	return 0;
}

static int fio_hdfsio_setup(struct thread_data *td)
{
	struct hdfsio_data *hd;
	struct fio_file *f;
	static unsigned int numjobs = 1;	/* atleast one job has to be there! */
	numjobs = (td->o.numjobs > numjobs) ? td->o.numjobs : numjobs;

	if (!td->io_ops->data) {
		hd = malloc(sizeof(*hd));;

		memset(hd, 0, sizeof(*hd));
		td->io_ops->data = hd;

		/* separate host and port from filename */
		*(strchr(td->o.filename, ',')) = ' ';
		sscanf(td->o.filename, "%s%d", hd->host, &(hd->port));

		/* read fbs and fcount and based on that set f->real_file_size */
		f = td->files[0];
#if 0
		/* IMHO, this should be done here instead of fio_hdfsio_prep()
		 * but somehow calling it here doesn't seem to work,
		 * some problem with libhdfs that needs to be debugged */
		hd->fs = hdfsConnect(hd->host, hd->port);
		fio_hdfsio_setup_fs_params(hd);
		hdfsDisconnect(hd->fs);
#else
		/* so, as an alternate, using environment variables */
		if (getenv("FIO_HDFS_FCOUNT") && getenv("FIO_HDFS_BS")) {
			hd->fscount = atol(getenv("FIO_HDFS_FCOUNT"));
			hd->fsbs = atol(getenv("FIO_HDFS_BS"));
		} else {
			fprintf(stderr,
				"FIO_HDFS_FCOUNT and/or FIO_HDFS_BS not set.\n");
			return 1;
		}
#endif
		f->real_file_size = hd->fscount * hd->fsbs;

		td->o.nr_files = 1;
		hd->curr_file_id = -1;
		hd->numjobs = numjobs;
		fio_file_set_size_known(f);
	}

	return 0;
}

static struct ioengine_ops ioengine_hdfs = {
	.name = "libhdfs",
	.version = FIO_IOOPS_VERSION,
	.setup = fio_hdfsio_setup,
	.prep = fio_hdfsio_prep,
	.queue = fio_hdfsio_queue,
	.open_file = fio_hdfsio_open_file,
	.close_file = fio_hdfsio_close_file,
	.flags = FIO_SYNCIO,
};

static void fio_init fio_hdfsio_register(void)
{
	register_ioengine(&ioengine_hdfs);
}

static void fio_exit fio_hdfsio_unregister(void)
{
	unregister_ioengine(&ioengine_hdfs);
}
