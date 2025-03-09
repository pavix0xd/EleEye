import pytest
import requests

BASE_SERVER_URL = "http://127.0.0.1:8000"

@pytest.fixture
def valid_payload():

    return {
        "color" : [255,255,255],
        "duration" : 15,
        "rate" : 2.5
    }

@pytest.fixture
def default_payload():
    return {
        "color" : [255,0,0],
        "duration" : 10,
        "rate" : 1
    }

def test_valid_warning_light_post_request(valid_payload):

    response = requests.post(f"{BASE_SERVER_URL}/warning_light", json=valid_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["received_data"] == valid_payload


@pytest.mark.parametrize(
        "payload, error_message",
        [
            ({"color" : [300,0,0], "duration" : 10, "rate" : 2.5}, "Color values must be integers between 0 and 255"),
            ({"color": "red", "duration": 10, "rate": 1}, "Color must be a list of three integers (RGB)"),
            ({"color": [255, 255, 255], "duration": -5, "rate": 1}, "Duration must be a positive integer"),
            ({"color": [255, 255, 255], "duration": 21, "rate": 1}, "Duration is too long"),
            ({"color": [255, 255, 255], "duration": 10, "rate": -1}, "Rate must be a positive integer/float"),
            ({"color": "invalid", "duration": -20, "rate": "invalid"}, ["Color must be a list of three integers (RGB)","Duration must be a positive integer","Rate must be a positive integer/float"])
        ],
)

def test_invalid_warning_light_post_request(payload, error_message):


    response = requests.post(f"{BASE_SERVER_URL}/warning_light", json=payload)
    assert response.status_code == 400
    data = response.json()
    assert data["status"] == "error"
    
    if isinstance(error_message, list):

        for message in error_message:
            assert message in "".join(data["message"]), f"Error message '{message}' should be in response. Response was: {data}"

    else:
        assert message in "".join(data["message"]), f"Error message '{message}' should be in response. Response was: {data}"


def test_missing_payload_warning_light_post_request(default_payload):

    response = requests.post(f"{BASE_SERVER_URL}/warning_light", json={})
    assert response.status_code == 200, "Missing payload should use defaults and return 200"
    data = response.json()
    assert data["status"] == "success", "Status should be success"
    assert data == default_payload , "Response should match default payload"

def test_invalid_endpoint():
    response = requests.get(f"{BASE_SERVER_URL}/invalid")
    assert response.status_code == 404, "Invalid endpoint should return 404"