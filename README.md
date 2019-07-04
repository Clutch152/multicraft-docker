Single Multicraft container. The container will be created with two locations internally '/mc/panel' and '/mc/multicraft'

These should be mounted to maintain config and data for both the server and the web front end.

/path/to:/mc/panel /path/to:/mc/multicraft

The individual server files can be found internally at '/mc/multicraft/servers/' in their own individual folder as set by within the Multicraft Panel. There are a handful of environmentals which can be set at start up as shown below. If you have purchased a Multicraft licence you should input this into MC_KEY, this will then be updated to allow you to access your full server licencing.

MC_DAEMON_ID="1"
MC_DAEMON_PW="ChangeMe"
MC_FTP_IP=""
MC_FTP_PORT="21"
MC_FTP_SERVER="y"
MC_KEY=""
You will need to specify thew port for each container and the public facing Panel. The panel internal port is port 80 and should be available either externally or to yourself locally and the game server ports should be both TCP and UDP e.g. 25565 TCP/UDP
