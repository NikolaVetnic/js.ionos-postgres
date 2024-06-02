# Setting Up a PostgreSQL Database on IONOS Cloud

What follows is a guide on setting up a Postgres database on IONOS cloud with access from the local dev environment.

Run Terraform with files in provided in this repository.

In the Data Center Designer, go to `server01`, then Network tab, get Primary IPv4 of `nic_public` (in this case `1.1.1.44`) and the same for `nic_private` (in this case `2.2.2.11`).

In the Data Center Designer, go to _Databases_ / _Postgres & MongoDB_, select the cluster (in this case `enmeshed_postgresql_cluster`) and scroll down to get the IP of Cluster to Datacenter Connection (in this case `2.2.2.9/24`).

Copy the SSH pair's public key to jumphost:

-   Automatically by trying to connect with `ssh root@1.1.1.44`, or if that doesn't work
-   Directly by running `ssh-copy-id enmeshed-user@1.1.1.44` (general form `ssh-copy-id username@jumphost_public_ip`), or if that also doesn't work
-   Manually, by connecting to jumphost via console from within the Data Center Designer as `root` using the password provided in the Terraform files, and then following these steps:
    -   On local machine, list the public key: `cat ~/.ssh/id_ed25519.pub`
    -   On local machine, copy the key and paste it into [Pastebin](https://pastebin.com/)
    -   On local machine, get the link of raw paste of form `https://pastebin.com/raw/xxxxxxxx`
    -   On jumphost, run `curl pastebin-link >> ~/.ssh/authorized_keys`
    -   On jumphost, confirm the key is appended by running `cat ~/.ssh/id_ed25519.pub`

Connect to `enmeshed` database via pgAdmin using the following data:

```yaml
	Connection:
	  Host name/address: 2.2.2.9 # Data Center -> Databases -> Postgres Clusters -> PostgreSQL_cluster -> Connections IP
	  Port: 5432
	  Maintenance database: postgres
	  Username: user # defined in main.tf
	  Password: Password

	SSH Tunnel:
	  Use SSH tunneling: true
	  Tunnel host: 1.1.1.44 # server01 -> Network tab -> nic_public Primary IPv4
	  Tunnel port: 22 # default
	  Username: root # default username of Ubuntu on server01
	  Authentication: Identity file
	  Identity file: path-to-id_rsa-file # the private key
```

Once connected, run the following SQL script via pgAdmin (note that the script is only valid for this particular scenario as all users are granted all privileges):

```sql
# PENDING
```

Finally, update `appsettings.override.json` files throughout the solution (right now there are four of these) with appropriate database connection strings. The format of the strings is as follows:

```json
{
    "ConnectionString": "Host=localhost;Port=5445;Username=user;Password=Password;Database=enmeshed;SslMode=Require;TrustServerCertificate=true"
}
```

In order to establish the connection to the database in the cloud an open SSH tunnel is required. The `localhost`'s port is something the user defines (I personally use `5445`), the usernames are set up in the SQL script, the password is set up in the script as well, while the database name is always `enmeshed`. The remaining parameters remain as is.

Finally before running the project open the SSH tunnel: `ssh -L 5445:2.2.2.9:5432 root@1.1.1.44 -N -i ~/.ssh/id_ed25519`

The parameters are:

-   The `localhost`'s port is something the user defines, in my case it is `5445`,
-   The target IP is the IP of the Postgres cluster on IONOS cloud,
-   The target port is standard Postgres port of `5432`,
-   What follows are the SSH parameters for the jumphost, i.e. the `root` user and the jumphost's IP, and finally
-   The last parameter is the user's private key of the previously generated pair.
