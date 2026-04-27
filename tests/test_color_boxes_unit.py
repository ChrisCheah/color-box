"""Unit tests for color_boxes Flask app using the test client."""


def test_hello(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.data.decode() == "Hello stranger!"


def test_list_empty(client):
    r = client.get("/box")
    assert r.status_code == 200
    body = r.data.decode()
    assert "Hello!" in body
    assert "<ul></ul>" in body


def test_create_box(client):
    r = client.post("/box/red")
    assert r.status_code == 200
    assert r.data.decode() == "Empty box 'red' created."


def test_create_duplicate_box(client):
    client.post("/box/red")
    r = client.post("/box/red")
    assert r.status_code == 200
    assert "already exists" in r.data.decode()


def test_get_existing_box(client):
    client.post("/box/blue")
    r = client.get("/box/blue")
    assert r.status_code == 200
    assert r.data.decode() == "Box 'blue' contains 0 balls."


def test_get_missing_box(client):
    r = client.get("/box/ghost")
    assert "No box 'ghost'" in r.data.decode()


def test_put_balls(client):
    client.post("/box/green")
    r = client.put("/box/green/7")
    assert r.status_code == 200
    assert r.data.decode() == "Box 'green' contains 7 balls."
    r = client.get("/box/green")
    assert "7 balls" in r.data.decode()


def test_put_balls_missing_box(client):
    r = client.put("/box/yellow/3")
    assert "No box 'yellow'" in r.data.decode()


def test_delete_box(client):
    client.post("/box/red")
    r = client.delete("/box/red")
    assert r.status_code == 200
    assert r.data.decode() == "Box 'red' deleted."
    r = client.get("/box/red")
    assert "No box 'red'" in r.data.decode()


def test_delete_missing_box(client):
    r = client.delete("/box/nope")
    assert "Cannot delete box 'nope'" in r.data.decode()


def test_list_with_boxes(client):
    client.post("/box/red")
    client.put("/box/red/2")
    client.post("/box/blue")
    body = client.get("/box").data.decode()
    assert "red has 2 balls" in body
    assert "blue has 0 balls" in body
