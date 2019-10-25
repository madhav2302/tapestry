# TAPESTRY

### Group Members
1.   Madhav Sodhani       :     1988-9109 
1.   Vaibhav Mohan Sahay  :     5454-1830

--- 

### Steps to run the Project:

1. Unzip the file Project3.tgz.  
   `unzip Project3.tgz`  
2. Change the directory to tapestry.  
   `cd tapestry` 
3. Run the project using:  
   `mix run project3.exs numNodes numRequests`
   

### Sample Output

```text
Number of nodes 100

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 3

real    0m9.851s
user    0m1.894s
sys     0m0.214s


Number of nodes 200

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m10.351s
user    0m3.886s
sys     0m0.251s


Number of nodes 300

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m10.938s
user    0m7.201s
sys     0m0.305s


Number of nodes 400

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m11.558s
user    0m11.906s
sys     0m0.359s


Number of nodes 500

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m12.477s
user    0m18.999s
sys     0m0.555s


Number of nodes 600

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m13.216s
user    0m25.940s
sys     0m0.553s


Number of nodes 700

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m14.864s
user    0m40.074s
sys     0m0.894s


Number of nodes 800

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m16.172s
user    0m56.696s
sys     0m0.928s


Number of nodes 900

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m18.480s
user    1m21.449s
sys     0m1.376s


Number of nodes 1000

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 4

real    0m21.429s
user    1m54.230s
sys     0m2.030s


Number of nodes 1500

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    0m37.353s
user    4m37.371s
sys     0m5.223s


Number of nodes 2000

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    1m2.227s
user    9m16.619s
sys     0m11.525s


Number of nodes 2500

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    1m29.764s
user    14m19.273s
sys     0m13.116s


Number of nodes 3000

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    2m8.828s
user    21m29.200s
sys     0m22.096s


Number of nodes 3500

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    2m56.866s
user    29m56.370s
sys     0m20.594s


Number of nodes 4000

Initialize DHT
Insert nodes dynamically
^[[CStart Requests
Max number of hops taken are 5

real    4m12.687s
user    41m2.768s
sys     1m45.523s


Number of nodes 4500

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    5m41.383s
user    52m50.809s
sys     2m9.054s


Number of nodes 5000

Initialize DHT
Insert nodes dynamically
Start Requests
Max number of hops taken are 5

real    7m26.876s
user    69m50.378s
sys     2m40.807s
```
---
### What is Working
```text
Distributed Hashtable - All the nodes in the network are assigned a GUID based on base 16 SHA algorithm.  
The corresponding value to the GUID will be the neighbouring nodes to which the message has to be passed.  
The routing table will have 40 levels because of the 40 character GUID.

Routing - Routing is carried out using the routing table and the message is transmitted to the neighbours by  
doing a lookup to the routing table. The API RouteToNode is implemented.

Dynamic node inserting - 1% of the nodes are being instrted dynamically.
```

--- 
### Largest Network


```text
5000 nodes with 5 hops
```

