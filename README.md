# H1Z1-Server

## What is this project?

This project aim to make a server for the 2015/2016 version of H1Z1.

**How to use?**

Just compile the project via Visual Studio and start the server, by default it starts on `localhost:20042`.
Open your game folder then edit the `ClientConfig.ini` file at the second line and set the LoginServer IP & Port.
Copy the `Launcher.exe` file from the git repo and paste it into the game folder, you will have to use this launcher to start the game.

You can also download the 2015 version of the game via steam if you bought H1Z1 by typing `download_depot 295110 295111 8395659676467739522` in the steam console.

## State

- [x] Handle client connection request (you'll still be on the loading screen but the `BaseApi` is setup & connected)
- [ ] Handle steam connection request 
- [ ] Send server data to the client

## Credits

[loguru](https://github.com/emilk/loguru) - for the log utility

[cpp-httplib](https://github.com/ChriisH/cpp-httplib) - for the http server

[rapidjson](https://github.com/) - for the json utility
