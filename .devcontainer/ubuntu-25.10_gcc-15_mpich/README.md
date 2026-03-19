# Community Fire Behavior Model Dev Container: ubuntu-25.10_gcc-15_mpich

This image provides a ready-to-build Community Fire Behavior Model (CFBM) development environment with GCC-15, MPICH, and scientific libraries installed through Spack.

For general Community Fire Behavior Model project information, see the [CFBM Documentation](https://ral.ucar.edu/model/community-fire-behavior-model).

## Installed Toolchain

The Dockerfile builds from `ubuntu:25.10` with the following components:

- GCC, G++, and GFortran 15.2
- Spack 1.1
- MPICH (ubuntu package, detected dynamically)
- NetCDF-C (ubuntu package, detected dynamically)
- NetCDF-Fortran (ubuntu package, detected dynamically)
- Python 3 (ubuntu package, detected dynamically)
- py-pyyaml (ubuntu package, detected dynamically)
- ParallelIO 2.6
- ESMF 8.8

## Environment

Start the container with `bash -l` to load the Spack-managed environment automatically.

| Environment Variable | Description |
|----------------------|-------------|
| `SPACK_ROOT` | Path to the Spack installation |
| `MPICH_ROOT` | Path to the MPICH installation |
| `NETCDF_C_ROOT` | Path to the NetCDF C installation |
| `NETCDF_FORTRAN_ROOT` | Path to the NetCDF Fortran installation |
| `PARALLELIO_ROOT` | Path to the ParallelIO installation |
| `ESMF_ROOT` | Path to the ESMF installation |
| `LD_LIBRARY_PATH` | Library search path including installed dependencies |

## Docker Usage

### Build the image

From `.devcontainer/ubuntu-25.10_gcc-15_mpich/`:

```bash
docker build -t cfbmdev_ubuntu-25.10_gcc-15_mpich .
```

### Run an interactive shell

```bash
docker run --rm -it cfbmdev_ubuntu-25.10_gcc-15_mpich bash -l
```

### Run an interactive shell with mounted local fire_behavior folder

From the repository root:

```bash
docker run --rm -it \
	-v "$PWD:/home/cfbm-dev/fire_behavior" \
	-w /home/cfbm-dev/fire_behavior \
	cfbmdev_ubuntu-25.10_gcc-15_mpich \
	bash -l
```

## Build Community Fire Behavior Model

With the repository mounted at `/home/cfbm-dev/fire_behavior`, a typical build is:

```bash
./compile.sh
```

The following options can be added to the build, see `--help` for a full list:

- `--mpi-off` - build without mpi library
- `--nuopc`, `-n` - build NUOPC library and module
- `--esmx`, `-x` - build ESMX application (includes NUOPC)
- `--openmp-on` - enable OpenMP parallelization
- `--verbose`, `-v` - build with verbose output
- `--test[=TEST_NAME]`, `-t[=TEST_NAME]` - run tests
- `--clean` - delete build and install directories

## Troubleshooting

**Environment variables are missing**

Start a login shell with `bash -l` so `/etc/profile.d/cfbm_spack.sh` is sourced.

**The container exits immediately**

Run an interactive shell, `-it`.

**Docker is using too much disk space**

Inspect usage with `docker system df` and remove unused images or containers with `docker system prune`.
