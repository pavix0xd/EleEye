import socket, re, cv2
from urllib.parse import urlparse


def test_sdp(rtsp_url: str):

    """
    Connects to the RTSP server, sends a DESCRIBE request, 
    and looks for geolocation (latitude and longitude) in the SDP.
    Returns a tuple if found, otherwise none
    """

    parsed = urlparse(rtsp_url)
    host = parsed.hostname
    port = parsed.port if parsed.port else 554
    path = path.parsed

    if parsed.query:
        path += "?" + parsed.query
    
    try:

        # Establish a TCP conection to the RTSP server
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        s.connect((host,port))

        request = (
            f"DESCRIBE {rtsp_url} RTSP/1.0\r\n"
            "CSeq: 1\r\n"
            "Accept: application/sdp\r\n\r\n"
        )

        s.send(request.encode())

        response = b""
        while True:
            data = s.recv(4096)
            if not data:
                break
            response += data

            if b"\r\n\r\n" in response:
                break

        s.close()
    
    except Exception as e:
        print(f"Error connecting to RTSP server: {e}")
        return None
    
    parts = response.split(b"\r\n\r\n",1)

    if len(parts) < 2:
        print("SDP not found in RTSP DESCRIBE response")
        return None
    
    sdp = parts[1].decode(errors='ignore')
    print("SDP recieved")
    print(sdp)
    
    geo_match = re.search(r"a=geo:([\d\.\-]+);([\d\.\-]+)", sdp)
    if geo_match:
        latitude = geo_match.group(1)
        longitude = geo_match.group(2)
        print(f"Geolocation found in SDP: latitude={latitude}, longitude={longitude}")
        return (latitude, longitude)

    else:
        print("No geolocation (latitude/longitude) found in SDP.")
        return None

def test_rtsp_stream(rtsp_url):

    """
    Opens the RTSP stream using OpenCV and displays it in a window
    """

    cap = cv2.VideoCapture(rtsp_url)
    if not cap.isOpened():
        print("Error: Unable to open video stream")
        return None

    cv2.namedWindow("RTSP Stream", cv2.WINDOW_NORMAL)

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Failed to receive frame. Exiting.")
            return None

        cv2.imshow("RTSP Stream", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()