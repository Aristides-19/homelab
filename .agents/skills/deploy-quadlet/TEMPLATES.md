# deploy-quadlet Templates

## `pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <service-name>
spec:
  containers:
    - name: <container-name>
      image: <docker-image>:<tag>
      envFrom:
        - configMapRef:
            name: env
      ports:
        - containerPort: <port-inside-container>
          hostPort: <port-on-host-lxc>
      volumeMounts:
        - name: data-volume
          mountPath: /data
  volumes:
    - name: data-volume
      hostPath:
        path: /data/<service-name>
        type: DirectoryOrCreate
```

## `pod.kube`
```ini
[Unit]
Description=<Service Name> Pod (Podman Quadlet KUBE)
After=network-online.target

[Kube]
Yaml=/opt/<service-name>/pod.yaml
ConfigMap=/opt/<service-name>/env.yaml

[Install]
WantedBy=multi-user.target
```

## `env.sample.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: env
data:
  PORT: "3000"
  LOG_LEVEL: "info"
```

## `setup.sh`
```bash
#!/bin/bash
mkdir -p /etc/containers/systemd/
cp /opt/<service-name>/pod.kube /etc/containers/systemd/<service-name>.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl start <service-name>' to start pod."
```
