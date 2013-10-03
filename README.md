URLSessionTest
==============
nevyn@lookback.io

URLSessionTest is a minimal test app to show how to use NSURLSession to upload files in the background. The code isn't pretty, the organization of code is flawed, but it highlights all the important parts.

Since I've struggled to understand various NSURLSession concepts the past few days, I thought I'd share it, so that it can be used as reference for whoever needs a hint when getting stuck.

How to run
----------
Put upload.php somewhere on a web server with PHP support. Change NEVViewController.m:87 to point to it. `tail -f /tmp/access.log` in a terminal to watch what's happening. Run URLSessionTest on a device or simulator, tap "Start upload" a few times, and you should see this in your tail terminal:

    192.168.32.74 GET  /upload.php b5631 for 10485760 bytes
    192.168.32.74 10% /upload.php b5631
    192.168.32.74 GET  /upload.php 5b7d8 for 10485760 bytes
    192.168.32.74 10% /upload.php 5b7d8
    192.168.32.74 20% /upload.php b5631
    ...
    192.168.32.74 DONE /upload.php b5631
    192.168.32.74 DONE /upload.php 5b7d8

In the simulator, you can see what NSURLSession thinks about the upload. You can even terminate the app ("Terminate" button) and it will be completely dead, yet your upload will continue. You can then relaunch the app and see the progress of your uploads.

What I've learned
-----------------

`-[NSURLSessionTask taskDescription]` is a good way to link an upload task to a file on disk, so you know which file an upload is about even after your app has restarted.

Create a good (probably UUID) session identifier, and keep track of it. `-[UIApplicationDelegate application:handleEventsForBackgroundURLSession:]` is ONLY interesting for updating your app screenshot after receiving data, and is completely uninteresting in this context. Instead, just make sure that you create an instance of whatever controller you have handling the upload when the app starts, so you can receive delegate methods. (don't put your URLSession in your viewcontroller, unless you can guarantee that the VC will live when the app starts (though in general, never put communication code in a VC)). 

`-[NSURLSessionTask URLSession:task:didCompleteWithError` is the delegate method you're looking for, and as long as you create the session correctly on app start, it's guaranteed to be called once the upload is completed. It's fine to use it for cleaning up temporary files after an upload.

Don't forget to `-[NSURLSession getTasksWithCompletionHandler:]` to see if you're already uploading stuff before you start another upload of the same file.

If you lose network connectivity or for some other reason get an interrupted upload, iOS will retry the upload without asking you. Be aware so you don't accidentally have side effects from an upload.

If it hasn't hit home yet: your application will automatically be launched when the upload finishes. You shouldn't run a UIBackgroundTask while uploading, but make sure to have one around other asynchronous things you might do as part of preparation for the upload, or cleanup after the upload.

I don't know what the point is of `-[NSURLSession finishTasksAndInvalidate:]`.

It seems a background upload task continues no matter what, even if the app is uninstalled.

What I still don't understand
-----------------------------

In my test app, only 128kb gets uploaded. o_O

