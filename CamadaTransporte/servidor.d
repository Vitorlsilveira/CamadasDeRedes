import Socket.d;
import InternetAddress.d;

void main() {
	//create a tcp/ip server on port 1234 tcp
	auto server = new ServerSocket(new InternetAddress("localhost", 1234));
	//enter into an infinite loop to process all the clients who will connect to us	
	while(1){
		auto client = server.accept();
	//client is a Socket class and it is the socket with the accepted client
	// to know how to use it read the following paragraph			
	}
}
