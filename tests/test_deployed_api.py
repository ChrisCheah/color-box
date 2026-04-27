"""End-to-end tests against a deployed color-box API.

Set ``COLORBOX_BASE_URL`` (e.g. ``http://127.0.0.1:8081``) before running, e.g.::

    kubectl -n mdata-toolkit port-forward svc/colorbox 8081:80
    $env:COLORBOX_BASE_URL = "http://127.0.0.1:8081"
    pytest tests/test_deployed_api.py -v
"""
import uuid

import pytest
import urllib.request
import urllib.error


def _request(method, url, timeout=10):
    req = urllib.request.Request(url, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


@pytest.fixture()
def color(base_url):
    """Unique color per test so runs don't collide on shared deployments."""
    c = f"t{uuid.uuid4().hex[:8]}"
    yield c
    # best-effort cleanup
    _request("DELETE", f"{base_url}/box/{c}")


def test_hello(base_url):
    status, body = _request("GET", f"{base_url}/")
    assert status == 200
    assert body == "Hello stranger!"


def test_list_endpoint_reachable(base_url):
    status, body = _request("GET", f"{base_url}/box")
    assert status == 200
    assert "boxes" in body


def test_full_lifecycle(base_url, color):
    # Create
    status, body = _request("POST", f"{base_url}/box/{color}")
    assert status == 200
    assert f"Empty box '{color}' created." == body

    # Get
    status, body = _request("GET", f"{base_url}/box/{color}")
    assert status == 200
    assert "0 balls" in body

    # Update
    status, body = _request("PUT", f"{base_url}/box/{color}/5")
    assert status == 200
    assert "5 balls" in body

    # Verify update persisted
    status, body = _request("GET", f"{base_url}/box/{color}")
    assert "5 balls" in body

    # Delete
    status, body = _request("DELETE", f"{base_url}/box/{color}")
    assert status == 200
    assert f"Box '{color}' deleted." == body

    # Confirm gone
    status, body = _request("GET", f"{base_url}/box/{color}")
    assert f"No box '{color}'" in body


def test_duplicate_create_is_rejected(base_url, color):
    _request("POST", f"{base_url}/box/{color}")
    status, body = _request("POST", f"{base_url}/box/{color}")
    assert status == 200
    assert "already exists" in body
