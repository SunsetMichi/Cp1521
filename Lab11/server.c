//
// server.c -- A webserver written in C
// 
// Test with curl
// 
//    curl -D - http://localhost:3490/
//    curl -D - http://localhost:3490/date
//    curl -D - http://localhost:3490/hello
//    curl -D - http://localhost:3490/hello?You
// 
// You can also test the above URLs in your browser! They should work!


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>
#include <time.h>
#include <sys/file.h>
#include <fcntl.h>
#include <error.h>

#define PORT 5000  // the port users will be connecting to
#define BACKLOG 10	 // how many pending connections queue will hold

#define BUF_SIZE 65536

void failed(char *);

// Send an HTTP response
//
// header:       "HTTP/1.1 404 NOT FOUND" or "HTTP/1.1 200 OK", etc.
// content_type: "text/plain", etc.
// body:         the data to send.
// 
int send_response(int fd, char *header, char *content_type, char *body)
{
   char response[BUF_SIZE];
   int response_length; // Total length of header plus body

   sprintf(response, "%s\n%s\r\n\r\n%s\n", header, content_type, body);
   response_length = strlen(response);
   int rv = send(fd, response, response_length, 0);
   if (rv < 0) failed("send");
   return rv;
}

// Send a 404 response
void send_404(int fd)
{
   send_response(fd, "HTTP/1.1 404 NOT FOUND",
                     "text/html",
                     "<h1>404 Page Not Found</h1>");
}

// Send a 500 response
void send_500(int fd)
{
   send_response(fd, "HTTP/1.1 500 Internal Server Error",
                     "text/html",
                     "<h1>Mangled request</h1>");
}

// Send response for server root
void send_root(int fd)
{
    //TODO
    send_response(fd, "HTTP/1.1 200 OK",
                      "text/html",
                      "<h1>Server running ...</h1>");
}

// Send a /date endpoint response
void send_date(int fd)
{
    //TODO
    time_t curtime;
    time(&curtime);
    char stime[100] = {'\0'};
    strcpy(stime, "<h1>");
    strcat(stime, ctime(&curtime));
    strcat(stime, "</h1>");
    send_response(fd, "HTTP/1.1 200 OK",
                      "text/html",
                      stime);
}

// Send a /hello endpoint response
void send_hello(int fd, char *req)
{
    //TODO
    if(strcmp("/hello",req) == 0){
        send_response(fd, "HTTP/1.1 200 OK",
                      "text/html",
                      "<h1>Hello</h1>");
    } else {
        char response[BUF_SIZE];
        strcpy(response, "<h1>");
        strcat(response, "Hello");
        strcat(response, ",");
        strcat(response, &req[7]);
        strcat(response, "!");
        strcat(response, "</h1>");
        send_response(fd, "HTTP/1.1 200 OK", "text/html", response);
    }                 
}

// Handle HTTP request and send response
void handle_http_request(int fd)
{
   char request[BUF_SIZE];
   char req_type[8]; // GET or POST
   char req_path[1024]; // /info etc.
   char req_protocol[128]; // HTTP/1.1
 
   // Read the request
   int nbytes = recv(fd, request, BUF_SIZE-1, 0);
   if (nbytes < 0) failed("recv");
   request[nbytes] = '\0';

   printf("Request: ");
   for (char *c = request; *c != '\n'; c++)
      putchar(*c);
   putchar('\n');
 
   // Get the request type and path from the first line
   // If you can't decode the request, generate a 500 error response
   // Otherwise call appropriate handler function, based on path
   // Hint: use sscanf() and strcmp()

   // TODO
   // strcmp if the path is equal to / call send root
   // strcmp if the path is equal to date call send date mothod
   // strcmp if the path has hello call send hello
   if(sscanf(request, "%s %s %s", req_type, req_path, req_protocol) < 3){
        send_500(fd);
   } else {
        if(strcmp(req_path, "/") == 0){
            send_root(fd);
        } else if(strcmp(req_path, "/date") == 0){
            send_date(fd);
        } else if((strcmp(req_path, "/hello") == 0) || strchr(req_path, '?') != NULL){
            send_hello(fd, req_path);
        } else {
            send_404(fd);
        }
   }
}

// fatal error handler
void failed(char *msg)
{
   char buf[100];
   sprintf(buf, "WebServer: %s", msg);
   perror(buf);
   exit(1);
}

int main(int argc, char *argv[])
{
   int listenfd;
   struct addrinfo hints;
   struct addrinfo *res;
   char portString[5]; 
   sprintf(portString,"%d", PORT);

   // set up a socket
   listenfd = socket(AF_INET, SOCK_STREAM, 0);
   if (listenfd < 0) failed("opening socket");
   setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int));
   memset(&hints, 0, sizeof hints);
   hints.ai_family = AF_INET;  // use IPv4  
   hints.ai_socktype = SOCK_STREAM;    
   getaddrinfo("localhost",portString,&hints,&res);

   // bind the socket to the address, set up in res
   // call fail if bind fails
   // listen for connections to that address  (used BACKLOG constant)
   // fall fail if listen fails
   // call freeaddrinfo on res 
   //TODO
   
   //Open socket connection
   //bind(socket, res->socketAddress, size)
   //listen(socket, backlog)
   if(bind(listenfd, res->ai_addr, res->ai_addrlen) == -1){
    error(errno, errno, "bind ");
   }
   if(listen(listenfd, BACKLOG) < 0){
    error(errno, errno, "listen ");
   }
   freeaddrinfo(res);
   printf("WebServer: waiting for connections...\n");
   
   
   while(1){ 
      //accept new request
      // call fail if accept fails
      //TODO
      struct sockaddr_in client_addr;
      socklen_t client_addr_size = sizeof(client_addr);
      int clientSocket;
      if((clientSocket = accept(listenfd, (struct sockaddr *) &client_addr, &client_addr_size)) < 0){
        error(errno, errno, "accept ");
      }
      
      printf("WebServer: got connection\n");

      // call handle_http_request, passing in the new socket 
      // descriptor for the new connection, returned from accept
      // Note: listenfd is still listening for new connections.
      // close the new socket descriptor.
      // TODO 
      // call handle_http_request
      handle_http_request(clientSocket);
   }
   close(listenfd);
   return 0; /* we never get here */
}
