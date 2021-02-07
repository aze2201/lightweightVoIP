# lightweightVoIP with PeerJS
1. user need to create file in cache folder <username>_token and <username>.csrf
2. Need to execute command to start server
  <pre>
  python3 socketGateway3.py
  </pre>
3. Start first client for manage incoming request over FIFO file
  <pre>
  ./RootRules.sh
  </pre>

4. Start Web Server and Client html project to connect with WebRTC and WebSocker. 
