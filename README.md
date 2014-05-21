COMP 8505 Final Project
===
Summer 2014 - chriswood.ca@gmail.com

Objective
---
  - To bring together several stealth software and backdoor concepts into a single covert communication application
  - To learn how to use such an application in allowing stealthy access to a network or to exfiltrate data from systems within a network

Mission
---
Design and implement a complete covert application that will allow a user to open a port (that is otherwise closed) on a firewall and communicate with a "disguised" backdoor application. The backdoor application will accept commands and execute them; the results of the command execution will be sent back to the remote client application.

Server Component
---
This is the component that will be installed on a machine from which the data is to be exfiltrated. It will be described in 2 parts.

#### Part 1
The application will
  - accept packets regardless of local firewall rules, meaning this part will be implemented with [libpcap]
  - run as a disguised process; obscure as possible
  - only accept authenticated packets (can be done with encrypted password in header field or payload)
  - extract encrypted commands from authenticated packets and execute that command
  - return the result of the command using a **covert channel**
  - use a separate channel to send the above rather than the original channel used to connect to the backdoor
  - provide a configuration file to configure server parameters

#### Part 2
This component of the server will implement port knocking for the covert channel to access the client component and deliver the exflitrated data.
The application will
  - generate a special sequence of packets or "knocks", authenticate the sequence and acquire access to the requested port and application.
  - close access to the ports again when exfiltration is complete (time or packet sequence controlled - user specified?)
 
Client Component
---
This is the component that the "hacker" would use to connect to the remote system via the backdoor.
The application will
  - have all the features to connect to and control the remote system
  - provide exfiltration function, aside from executing remote commands. User will be able to specify covert search or file/directory watch to be sent back to the client covertly
  - accept and decode a specific knock sequence, provide access to the port and service that will be accepting all encrypted data (results of command execution or exfiltrated file)
  - provide a configuration file to configure the client parameters

Constraints
---
  - Implementation of application can be for Linux or Windows
  - User must be able to select a number of protocols (UDP, TCP, etc) and ports to carry out the penetration and exfiltration
  - Detailed user guide or README must be included
  - Submission must include a brief technical report commenting on your protocol designed for implementation together with ways in which the covert activity could be detected and recommendations on how to stop such activity

[libpcap]:https://github.com/the-tcpdump-group/libpcap
