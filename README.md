<div align="center">

![logo-large 72ad8bf1](https://user-images.githubusercontent.com/5213906/77421237-6d402180-6e06-11ea-89c1-915cd747660a.png)

# Private PyPI

**The private PyPI server powered by flexible backends.**

[![build-and-push](https://github.com/private-pypi/private-pypi/workflows/build-and-push/badge.svg)](https://github.com/private-pypi/private-pypi/actions?query=workflow%3Abuild-and-push)
[![license](https://img.shields.io/github/license/private-pypi/private-pypi)](https://github.com/private-pypi/private-pypi/blob/master/LICENSE)

</div>

## What is it?

`private-pypi` allows you to deploy a PyPI server privately and keep your artifacts safe by leveraging the power (confidentiality, integrity and availability) of your storage backend. The backend mechanism is designed to be flexible so that the developer could support a new storage backend at a low cost.

Supported backends:

- GitHub. (Yes, you can now host your Python package in GitHub by using `private-pypi`. )
- File system.
- ... (*Upcoming*)

## Design

<div align="center"><img width="766" alt="Screen Shot 2020-03-24 at 8 19 12 PM" src="https://user-images.githubusercontent.com/5213906/77424853-c14e0480-6e0c-11ea-9a7f-879a68ada0a0.png"></div>

The `private-pypi` server serves as an abstraction layer between Python package management tools (pip/poetry/twine) and the storage backends:

* Package management tools communicate with `private-pypi` server, following [PEP 503 -- Simple Repository API](https://www.python.org/dev/peps/pep-0503/) for searching/downloading package, and [Legacy API](https://warehouse.pypa.io/api-reference/legacy/#upload-api) for uploading package.
* `private-pypi server`  then performs file search/download/upload operations with some specific storage backend.

## Usage

### Install from PyPI

```shell
pip install private-pypi==0.1.0a17
```

This should bring the execuable `private_pypi` to your environment.

```shell
$ private_pypi --help
SYNOPSIS
    private_pypi <command> <command_flags>

SUPPORTED COMMANDS
    server
    update_index
    github.init_pkg_repo
    github.gen_gh_pages
```

### Using the docker image (recommended)

Docker image: `privatepypi/private-pypi:0.1.0a17`. The image tag is the same as the package version in PyPI.

```shell
$ docker run --rm privatepypi/private-pypi:0.1.0a17 --help
SYNOPSIS
    private_pypi <command> <command_flags>

SUPPORTED COMMANDS
    server
    update_index
    github.init_pkg_repo
    github.gen_gh_pages
```

### Run the server

To run the server, use the command `private_pypi server`.

```shell
SYNOPSIS
    private_pypi server ROOT <flags>

POSITIONAL ARGUMENTS
    ROOT (str):
        Path to the root folder. This folder is for logging,
        file-based lock and any other file I/O.

FLAGS
    --config (Optional[str]):
        Path to the package repository config (TOML),
        or the file content if --config_or_admin_secret_can_be_text is set.
        Defaults to None.
    --admin_secret (Optional[str]):
        Path to the admin secrets config (TOML) with read/write permission.
        or the file content if --config_or_admin_secret_can_be_text is set.
        This field is required for local index synchronization.
        Defaults to None.
    --config_or_admin_secret_can_be_text (Optional[bool]):
        Enable passing the file content to --config or --admin_secret.
        Defaults to False.
    --auth_read_expires (int):
        The expiration time (in seconds) for read authentication.
        Defaults to 3600.
    --auth_write_expires (int):
        The expiration time (in seconds) for write authentication.
        Defaults to 300.
    --extra_index_url (str):
        Extra index url for redirection in case package not found.
        If set to empty string explicitly redirection will be suppressed.
        Defaults to 'https://pypi.org/simple/'.
    --debug (bool):
        Enable debug mode.
        Defaults to False.
    --host (str):
        The interface to bind to.
        Defaults to '0.0.0.0'.
    --port (int):
        The port to bind to.
        Defaults to 8888.
    **waitress_options (Dict[str, Any]):
        Optional arguments that `waitress.serve` takes.
        Details in https://docs.pylonsproject.org/projects/waitress/en/stable/arguments.html.
        Defaults to {}.
```

In short, the configuration passed to `--config` defines mappings from `pkg_repo_name` to backend-specific settings. In other words, a single server instance can be configured to connect to multiple backends.

### Server API

#### Authentication in shell

User must provide the `pkg_repo_name` and their secret in most of the API calls so that the server can find which backend to operate and determine whether the operation is permitted or not. The `pkg_repo_name` and the secret should be provided in [basic access authentication](https://en.wikipedia.org/wiki/Basic_access_authentication).

Some package management tools will handle the authentication behind the screen, for example,

* Twine: to set the environment variables `TWINE_USERNAME` and `TWINE_PASSWORD`. [ref](https://github.com/pypa/twine#environment-variables)
* Poetry: [Configuring credentials](https://python-poetry.org/docs/repositories/#configuring-credentials).

Some will not, for example,

* Pip: you need to prepend  `<pkg_repo_name>:<secret>@` to the hostname in the URL manually like this `https://[username[:password]@]pypi.company.com/simple`. [ref](https://pip.pypa.io/en/stable/user_guide/#basic-authentication-credentials)

#### Authentication in browser

You need to visit `/login` page to submit `pkg_repo_name` and the secret, since most of the browsers today don't support prepending `<username>:<password>@` to the hostname in the URL. The `pkg_repo_name` and the secret will be stored in the session cookies. To reset, visit `/logout` .

Example: `http://localhost:8888/login/`

<div align="center"><img width="600" alt="Screen Shot 2020-03-25 at 12 36 03 PM" src="https://user-images.githubusercontent.com/5213906/77502233-40871b00-6e95-11ea-8ac9-4844d7067ed2.png"></div>


#### PEP-503, Legacy API

The server follows [PEP 503 -- Simple Repository API](https://www.python.org/dev/peps/pep-0503/) and [Legacy API](https://warehouse.pypa.io/api-reference/legacy/#upload-api) to define APIs for searching/downloading/uploading package:

* `GET /simple/`: List all distributions.
* `GET /simple/<distrib>/`: List all packages in a distribution.
* `GET /simple/<distrib>/<filename>`: Download a package file.
* `POST /simple/`: Upload a package file.

In a nutshell, you need to set the "index url / repository url / ..." to `http://<host>:<port>/simple/` for the package management tool.

#### Private PyPI server management

##### `GET /index_mtime`

Get the last index index synchronization timestamp.

```shell
$ curl http://debug:foo@localhost:8888/index_mtime/
1584379892
```

##### `POST /initialize`

Submit configuration and (re-)initialize the server. User can change the package repository configuration on-the-fly with this API.

```shell
# POST the file content.
$ curl \
  -d "config=${CONFIG}&admin_secret=${ADMIN_SECRET}" \
  -X POST \
  http://localhost:8888/initialize/
# POST the file.
$ curl \
  -F 'config=@/path/to/config.toml' \
  -F 'admin_secret=@/path/to/admin_secret.toml' \
  http://localhost:8888/initialize/
```

### Update index

<div align="center"><img width="636" alt="Screen Shot 2020-03-25 at 5 39 19 PM" src="https://user-images.githubusercontent.com/5213906/77522697-9a043f80-6ebf-11ea-95e6-9a086db7af2e.png"></div>

Index file is used to track all published packages in a specific time:

* *Remote index file*: the index file sotred in the backend. By design, this file is only updated by a standalone `update index` service and will not be updated by the `private-pypi` server.
* *Local index file*: the index file synchronized from the remote index file by the `private-pypi` server 

To update the remote index file, use the command `private_pypi update_index`:

```shell
SYNOPSIS
    private_pypi update_index TYPE NAME <flags>

POSITIONAL ARGUMENTS
    TYPE (str):
        Backend type.
    NAME (str):
        Name of config.

FLAGS
    --secret (Optional[str]):
        The secret with write permission.
    --secret_env (Optional[str]):
        Instead of passing the secret through --secret,
        the secret could be loaded from the environment variable.
    **pkg_repo_configs (Dict[str, Any]):
        Any other backend-specific configs are allowed.
```

Backend developer could setup an `update index` service by invoking  `private_pypi update_index` command.

### Backend-specific commands

The backend registration mechanism will hook up the backend-specific commands to `private_pypi`. As illustrated, commands `github.init_pkg_repo` and `github.gen_gh_pages` are registered by `github` backend.

```shell
$ private_pypi --help
SYNOPSIS
    private_pypi <command> <command_flags>

SUPPORTED COMMANDS
    server
    update_index
    github.init_pkg_repo
    github.gen_gh_pages
```


### Environment mode

## Backends

### GitHub

### File system

