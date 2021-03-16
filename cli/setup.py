import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="stats-cli",
    version="0.0.1",
    author="NRSER",
    author_email="neil@nrser.com",
    description="Command Line Interface (CLI) for Stats app",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/nrser/stats",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "Operating System :: POSIX",
    ],
    python_requires='>=3.9',
    install_requires=[
        "rich>=9.13.0,<10",
        "argcomplete>=1.12.1,<2",
        "requests>=2.24.0,<3.0",
        "kafka-python>=2.0.2,<3",
        "beautifulsoup4>=4.9.3,<5",
        # midi experiment
        "python-rtmidi>=1.4.7,<2",
        # _creating_ Markdown, believe it or not
        "mdutils>=1.3.0,<2",
        # sorted containers for clavier.cfg
        "sortedcontainers>=2.3.0,<3",
    ],
    scripts = [
        'bin/stats',
    ],
)
