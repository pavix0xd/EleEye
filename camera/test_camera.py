import sys
from unittest.mock import MagicMock
import socket, re, cv2, errno, os, time, gc, subprocess, socket, psutil, logging, unittest, camera
from unittest.mock import patch, MagicMock, mock_open, call
from urllib.parse import urlparse


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

class TestFfmpegErrorHandler(unittest.TestCase):

    def test_broken_pipe(self):

        with self.assertLogs(camera.logger, level="INFO") as log:
            error = BrokenPipeError("broken FIFO pipe")
            camera.ffmpeg_error_handler(error)
        self.assertIn("[FFmpeg Error handler] Detected BrokenPipeError - FFmpeg likely crashed", "".join(log.output))

    def test_oserror_epipe(self):

        with self.assertLogs(camera.logger, level="INFO") as log:
            error = OSError(errno.EPIPE, "EPIPE error")
            camera.ffmpeg_error_handler(error)
        self.assertIn("EPIPE", "".join(log.output))

    def test_oserror_other(self):

        with self.assertLogs(camera.logger, level="INFO") as log:
            error = OSError(9999, "Unknown OS Error")
            camera.ffmpeg_error_handler(error)

        self.assertIn("OSError with errno=9999", "".join(log.output))

    def test_generic_exception(self):

        with self.assertLogs(camera.logger, level="INFO") as log:
            error = Exception("Generic exception")
            camera.ffmpeg_error_handler(error)
        self.assertIn("Unhandled exception type", "".join(log.output))


class TestCheckConnection(unittest.TestCase):

    @patch("socket.create_connection")
    def test_connection_success(self, mock_create):
        mock_create.return_value = True
        self.assertTrue(camera.check_connection("127.0.0.1", 80, timeout=1))
        mock_create.assert_called_with(("127.0.0.1", 80), timeout=1)

    @patch("socket.create_connection", side_effect=OSError)
    def test_connection_failure(self, mock_create):
        self.assertFalse(camera.check_connection("127.0.0.1", 80, timeout=1))


class TestKillConflictingProcesses(unittest.TestCase):

    @patch("camera.subprocess.check_output")
    @patch("camera.os.kill")
    def test_kill_conflicting_processes(self, mock_kill, mock_check_output):

        fake_output = "COMMAND PID USER\nsomeproc 1234 user\n"
        mock_check_output.return_value = fake_output.encode("utf-8")

        with patch("camera.os.getpid", return_value=9999):
            camera.kill_conflicting_processes(device="/dev/video")

        mock_kill.assert_called_with(1234, camera.signal.SIGTERM)

    @patch("camera.subprocess.check_output", side_effect=subprocess.CalledProcessError(1, "lsof"))
    def test_kill_conflicting_process_none_found(self, mock_check_output):

        with patch("camera.logger") as mock_logger:
            camera.kill_conflicting_processes(device="/dev/video0")


class TestFreeMemory(unittest.TestCase):

    @patch("camera.gc.collect", return_value=5)
    @patch("camera.os.system")
    @patch("camera.psutil.virtual_memory")
    @patch("camera.time.sleep", return_value=None)
    def test_memory(self, mock_sleep, mock_virtual_memory, mock_os_system, mock_gc):

        fake_mem = MagicMock()
        fake_mem.percent = 50
        fake_mem.available = 200 * 1024 * 1024  # 200 MB available
        mock_virtual_memory.return_value = fake_mem

        with self.assertLogs(camera.logger, level="INFO") as log:
            camera.free_memory()

        self.assertTrue(mock_os_system.called)
        self.assertIn("Garbage collection complete", "".join(log.output))


class TestReadLocationMetadata(unittest.TestCase):

    def test_valid_file(self):
        fake_file = "10.123\n20.456\n"
        with patch("builtins.open", mock_open(read_data=fake_file)):
            result = camera.read_location_metadata("dummy.txt")
            self.assertEqual(result, (10.123, 20.456))

    def test_invalid_line_count(self):
        fake_file = "10.123\n"
        with patch("builtins.open", mock_open(read_data=fake_file)):
            result = camera.read_location_metadata("dummy.txt")
            self.assertIsNone(result)

    def test_invalid_numbers(self):
        fake_file = "abc\ndef\n"
        with patch("builtins.open", mock_open(read_data=fake_file)):
            result = camera.read_location_metadata("dummy.txt")
            self.assertIsNone(result)


class TestCreateFfmpegOutput(unittest.TestCase):

    @patch("camera.read_location_metadata", return_value=(0.00000, 180.00000))
    @patch("camera.FfmpegOutput")
    def test_create_ffmpeg_output_with_location(self, mock_ffmpeg_output, mock_read_meta):

        dummy_output = MagicMock()
        mock_ffmpeg_output.return_value = dummy_output
        output = camera.create_ffmpeg_output()

        self.assertIn("lat=0.00000", mock_ffmpeg_output.call_args[0][0])
        self.assertIn("lon=180.00000", mock_ffmpeg_output.call_args[0][0])
        self.assertEqual(dummy_output.error_callback, camera.ffmpeg_error_handler)

    @patch("camera.read_location_metadata", return_value=None)
    @patch("camera.FfmpegOutput")
    def test_create_ffmpeg_output_without_location(self, mock_ffmpeg_output, mock_read_meta):

        dummy_output = MagicMock()
        mock_ffmpeg_output.return_value = dummy_output
        output = camera.create_ffmpeg_output()
        self.assertIn("rtsp://192.168.1.8:8554/test", mock_ffmpeg_output.call_args[0][0])


class TestStartCamera(unittest.TestCase):

    def setUp(self):

        self.picam_patch = patch("camera.Picamera2")
        self.mock_Picamera2 = self.picam_patch.start()
        self.ffmpeg_patch = patch("camera.create_ffmpeg_output")
        self.mock_create_ffmpeg = self.ffmpeg_patch.start()

        self.dummy_camera = MagicMock()
        self.dummy_camera.create_video_configuration.return_value = {
            "encode": "h264",
            "main": {"size": (640, 640)},
            "controls": {"FrameRate": 30}
        }

        self.mock_Picamera2.return_value = self.dummy_camera
        self.dummy_ffmpeg = MagicMock()
        self.mock_create_ffmpeg.return_value = self.dummy_ffmpeg
        self.kill_patch = patch("camera.kill_conflicting_processes")
        self.mock_kill = self.kill_patch.start()
        self.free_patch = patch("camera.free_memory")
        self.mock_free = self.free_patch.start()

    def tearDown(self):

        self.picam_patch.stop()
        self.ffmpeg_patch.stop()
        self.kill_patch.stop()
        self.free_patch.stop()

    def test_start_camera_success(self):

        cam, ffmpeg = camera.start_camera(max_tries=3)
        self.assertEqual(cam, self.dummy_camera)
        self.assertEqual(ffmpeg, self.dummy_ffmpeg)
        self.dummy_camera.configure.assert_called_once()

    def test_start_camera_oserror_ebusy(self):

        self.dummy_camera.create_video_configuration.return_value = {}
        self.dummy_camera.configure.side_effect = [OSError(errno.EBUSY, "busy"), None]
        cam, ffmpeg = camera.start_camera(max_tries=2)
        self.mock_kill.assert_called()
        self.assertEqual(cam, self.dummy_camera)
        self.assertEqual(ffmpeg, self.dummy_ffmpeg)

    def test_start_camera_oserror_enomem(self):

        self.dummy_camera.create_video_configuration.return_value = {}
        self.dummy_camera.configure.side_effect = [OSError(errno.ENOMEM, "out of memory"), None]
        cam, ffmpeg = camera.start_camera(max_tries=2)
        self.mock_free.assert_called()
        self.assertEqual(cam, self.dummy_camera)
        self.assertEqual(ffmpeg, self.dummy_ffmpeg)

    def test_start_camera_oserror_enodev(self):

        self.dummy_camera.create_video_configuration.return_value = {}
        self.dummy_camera.configure.side_effect = OSError(errno.ENODEV, "device not found")

        with self.assertRaises(SystemExit) as cm:
            camera.start_camera(max_tries=3)

        self.assertEqual(cm.exception.code, 1)

    def test_start_camera_runtime_error_buffer(self):

        config = {"main": {"size": (640, 640)}, "controls": {"FrameRate": 30}}
        self.dummy_camera.create_video_configuration.return_value = config
        self.dummy_camera.configure.side_effect = [RuntimeError("Buffer overflow Error"), None]
        cam, ffmpeg = camera.start_camera(max_tries=2)
        self.mock_free.assert_called()
        self.assertEqual(cam, self.dummy_camera)
        self.assertEqual(ffmpeg, self.dummy_ffmpeg)


class TestStartFileRecording(unittest.TestCase):

    def setUp(self):

        self.picam_patch = patch("camera.Picamera2")
        self.mock_Picamera2 = self.picam_patch.start()
        self.dummy_camera = MagicMock()
        self.mock_Picamera2.return_value = self.dummy_camera

        self.ffmpeg_file_patch = patch("camera.create_ffmpeg_output_file")
        self.mock_create_ffmpeg_file = self.ffmpeg_file_patch.start()
        self.dummy_ffmpeg_file = MagicMock()
        self.mock_create_ffmpeg_file.return_value = self.dummy_ffmpeg_file

    def tearDown(self):

        self.picam_patch.stop()
        self.ffmpeg_file_patch.stop()

    def test_start_file_recording_success(self):

        cam, ffmpeg = camera.start_file_recording("dummy.h264", max_tries=3)
        self.assertEqual(cam, self.dummy_camera)
        self.assertEqual(ffmpeg, self.dummy_ffmpeg_file)
        self.dummy_camera.configure.assert_called_once()


class TestStreamBufferToRTSP(unittest.TestCase):

    @patch("camera.subprocess.run")
    def test_stream_buffer_success(self, mock_run):

        camera.stream_buffer_to_rtsp("dummy.h264")
        expected_command = [
            "ffmpeg",
            "-re",
            "-i", "dummy.h264",
            "-c", "copy",
            "-rtsp_transport", "tcp",
            "-f", "rtsp",
            "rtsp://192.168.1.8:8554/stream"
        ]
        mock_run.assert_called_with(expected_command, check=True)

    @patch("camera.subprocess.run", side_effect=Exception("ffmpeg error"))
    @patch("camera.logger")
    def test_stream_buffer_failure(self, mock_logger, mock_run):

        camera.stream_buffer_to_rtsp("dummy.h264")
        mock_logger.error.assert_called()


class TestRestartFunctions(unittest.TestCase):

    def setUp(self):

        self.dummy_picam = MagicMock()
        self.dummy_ffmpeg = MagicMock()

    @patch("camera.time.sleep", return_value=None)
    def test_restart_recording(self, mock_sleep):

        camera.restart_recording(self.dummy_picam, self.dummy_ffmpeg)
        self.dummy_picam.stop_recording.assert_called()
        self.dummy_picam.stop.assert_called()
        self.dummy_picam.start_recording.assert_called()

    @patch("camera.time.sleep", return_value=None)
    def test_restart_ffmpeg_output(self, mock_sleep):

        camera.restart_ffmpeg_output(self.dummy_picam, self.dummy_ffmpeg)
        self.dummy_picam.stop_recording.assert_called()
        self.dummy_picam.stop.assert_called()
        self.dummy_ffmpeg.stop.assert_called()
        self.dummy_ffmpeg.start.assert_called()
        self.dummy_picam.start_recording.assert_called()
        self.dummy_picam.start.assert_called()


class TestModes(unittest.TestCase):

    def setUp(self):

        self.dummy_picam = MagicMock()
        self.dummy_ffmpeg = MagicMock()
        self.encoder = MagicMock()

    @patch("camera.check_connection", side_effect=[False])
    @patch("camera.time.sleep", side_effect=lambda x: (_ for _ in ()).throw(StopIteration))
    def test_live_mode(self, mock_sleep, mock_check):

        with self.assertRaises(StopIteration):
            camera.live_mode(self.dummy_picam, self.dummy_ffmpeg)

        self.dummy_picam.stop_recording.assert_called()
        self.dummy_picam.stop.assert_called()

    @patch("camera.check_connection", side_effect=[False])
    @patch("camera.time.sleep", side_effect=lambda x: (_ for _ in ()).throw(StopIteration))
    @patch("os.remove")
    def test_offline_mode(self, mock_remove, mock_sleep, mock_check):

        with self.assertRaises(StopIteration):
            camera.offline_mode(self.dummy_picam, self.dummy_ffmpeg, "dummy.h264", offline_timeout=1)

        self.dummy_picam.stop_recording.assert_called()
        self.dummy_picam.stop.assert_called()


if __name__ == "__main__":
    unittest.main()