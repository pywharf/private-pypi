<div align="center">

![logo-large 72ad8bf1](https://user-images.githubusercontent.com/5213906/77421237-6d402180-6e06-11ea-89c1-915cd747660a.png)

# Private PyPI

**The private PyPI server powered by flexible backends.**

[![build-and-push](https://github.com/private-pypi/private-pypi/workflows/build-and-push/badge.svg)](https://github.com/private-pypi/private-pypi/actions?query=workflow%3Abuild-and-push)
[![license](https://img.shields.io/github/license/private-pypi/private-pypi)](https://github.com/private-pypi/private-pypi/blob/master/LICENSE)

</div>

## What is it?

`private-pypi` allows you to deploy a PyPI server privately and keep your artifacts safe by leveraging the power (confidentiality, integrity and availability) of your storage backend. The backend mechanism is designed to be flexible so that the developer could attach to a new storage backend at a low cost.

Supported backends:

- GitHub. (Yes, you can now host your Python package in GitHub by using `private-pypi`. )
- File system.
- ... (*Upcoming*)

## Design

<div align="center">

![](https://user-images.githubusercontent.com/5213906/77424853-c14e0480-6e0c-11ea-9a7f-879a68ada0a0.png)

</div>

The `private-pypi server` serves as an abstraction layer between Python package management tools (pip/poetry/twine) and the storage backends:

* Package management tools communicate with `private-pypi server`, following [PEP 503 -- Simple Repository API](https://www.python.org/dev/peps/pep-0503/) for searching/downloading package, and [Legacy API](https://warehouse.pypa.io/api-reference/legacy/#upload-api) for uploading package.
* `private-pypi server`  then performs file search/download/upload operations with some specific storage backend. The backend-specific operations are implemented in the standard backend interfaces in order to minimize the cost of adding new backends.

## Usage

`private-pypi server`:

```txt
Run the private-pypi server.

SYNOPSIS
    private_pypi_server ROOT <flags>

POSITIONAL ARGUMENTS
    ROOT (str):
        Path to the root folder.

FLAGS
    --config (Optional[str]):
        Path to the package repository config,
        or the file content if --config_or_admin_secret_can_be_text is set.
        Defaults to None.
    --admin_secret (Optional[str]):
        Path to the admin secrets config with read/write permission.
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

## Backends

### GitHub

### File system
