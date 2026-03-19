# Community Fire Behavior Model Dev Containers

This directory contains the Community Fire Behavior Model (CFBM) development container definitions used for local Docker workflows and VS Code Dev Containers.

## Purpose

Dev containers provide a reproducible environment with the compilers, MPI libraries, and scientific libraries required to build the Community Fire Behavior Model. Each container variant lives in its own directory and includes:

- `devcontainer.json` for VS Code Dev Containers
- `Dockerfile` and supporting container files
- `README` with variant-specific usage notes

## Available Dev Containers

Container directories are named as `<os>-<compiler>-<mpi>` so additional variants can be added without changing the layout of this directory.

| Variant | Summary |
|---------|---------|
| [ubuntu-25.10_gcc-14_mpich](ubuntu-25.10_gcc-14_mpich/) | GCC-14 and MPICH development environment with Spack-managed CFBM dependencies |

## VS Code Usage

Install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for Visual Studio Code.

Open the repository in VS Code, choose `Reopen in Container`, and select the desired container. The workspace is typically mounted at `/home/cfbm-dev/fire_behavior`, and the integrated terminal starts as a login shell.

## Notes

For background on Docker itself, see the [Docker documentation](https://docs.docker.com/).
