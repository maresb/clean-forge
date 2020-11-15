# clean-forge
Add a clean and customizable conda to a Docker image

(in development)

## Motivation

**[Anaconda](https://www.anaconda.com/)** is the industry standard tool for package management and reproducible environments in data science. Unlike [pip](https://pypi.org/project/pip/) and relatives, Anaconda takes package management beyond Python, allowing for the installation of external (non-Python) dependencies, such as linear algebra libraries. That is why Anaconda is the recommended method for [installing packages such as numpy](https://numpy.org/install/).

Anaconda is rather bloated for usage in small projects, but thankfully there is a [minimalist version called **Miniconda**](https://docs.conda.io/en/latest/miniconda.html).

The package manager at the core of Anaconda and Miniconda is called **`conda`**. It performs sophisticated satisfiability checks to determine which packages to install, and is implemented in Python.

For projects with a large number of dependencies, `conda` is obscenely slow. [**Mamba**](https://github.com/mamba-org/mamba) reimplements conda in C++, solving these performance issues.

Adding to the complexity in the Conda world, in addition to the default package channel, there is a community-maintained channel called [**`conda-forge`**](https://conda-forge.org/) which in general is larger and better maintained.

For purposes of CI/CD, it's desirable to have several alternative Docker containers available, based on a wide variety of possible configurations. For example: 
* various base images (and with various version tags):
  * [`alpine`](https://hub.docker.com/_/alpine)
  * [`debian`](https://hub.docker.com/_/debian)
  * [`ubuntu`](https://hub.docker.com/_/ubuntu)
* various Python versions:
  * 2.7
  * 3.6
  * 3.7
  * 3.8
  * 3.9
  * none (unlike Conda, Mamba has no dependency on Python)

Although far from widespread, it is considered best practice with Docker to run containers as a **non-root user**.

Finally, bash scripting is atrociously archaic, with painful syntax and innumerable pitfalls. The [**xonsh**](https://xon.sh/) project is a Python-centric shell and scripting language which is mostly backwards-compatible with bash.

Clean-forge aims to provide a basis for extending existing Docker images with
* **Mamba** as a package manager
* **Conda-forge** as the default package channel
* Prebuilt images based on various combinations of base images and versions of Python
* **Xonsh** as an available shell for sane scripting
* A configurable **user account** with access to all these tools
