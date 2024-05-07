# DL VS Code Server

This script downloads a tar of VS Code Server, then extracts it to a location expected by VS Code clients. The intention of this script is to download and setup the server during image build. This helps to ensure in certain scenarios that the server is there when internet is not, while still allowing your VS code client to connect to it.

Another reason is to prevent the constand download and install of VS Code server when the container is removed then run again later. With the sever being embeded in the image, it should not need to download until an update to VS Code itself, which would expect a new version of the server.