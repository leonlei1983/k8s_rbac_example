# Example to create different role

* log reader
* configmap mantainer
* deployment
* administator

### Create User

```
./create_user.sh <username> <group> <expiration days>
```

### Create Service Account

```
./create_service_account.sh <username>
```

### Grant permission

```
kubectl apply -f rbac/
```

### Start to access kubernetes
