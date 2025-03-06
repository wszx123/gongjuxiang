# 22/Port 50100/' 50100为要修改的端口
sed -i 's/#Port 22\|Port 22/Port 50100/' /etc/ssh/sshd_config && service ssh restart