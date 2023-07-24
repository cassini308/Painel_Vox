#!/bin/sh
##### Instalacao do servidor do painel de streaming de audio #####

# Cores
EfeitoCorTitulo="\033[0;35m"
EfeitoCorOK="\033[0;32m"
EfeitoCorAlerta="\033[1;33m"
EfeitoCorErro="\033[0;31m"
EfeitoFecha="\033[0m"

# Variaveis gerais
versao_centos=`/bin/rpm -qa centos-release | cut -d '-' -f 3 | cut -d . -f 1`
senha_ftp=`date +%s | sha256sum | base64 | head -c 15`
senha_pp=`date +%s | sha256sum | base64 | head -c 20`
senha_painel_mysql=`date +%s | sha256sum | base64 | head -c 15`
senha_root_mysql=`date +%s | sha256sum | base64 | head -c 30`
senha_admin_painel=`date +%s | sha256sum | base64 | head -c 10`

clear

if [ "$1" == "--help" ]; then

echo
echo -e "$EfeitoCorTitulo Modo de uso: sh instalador-painel-stm-audio-multi-centos.sh OPCOES $EfeitoFecha"
echo
echo -e "$EfeitoCorTitulo --skip-inter          Desativa modo interativo para que não seja necessário aperta teclas para continuar $EfeitoFecha"
echo -e "$EfeitoCorTitulo --ssl                 Instala somente SSL $EfeitoFecha"
echo
exit

fi

echo
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorTitulo # Script de Instalação do Painel de Streaming de Audio # $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo

if [ x`echo "$1" | egrep -c "\-\-app|\-\-ssl"` = x0 ]; then

echo -e "$EfeitoCorOK Instalação Painel Audio & Video CentOS(7/8) $EfeitoFecha"
echo

echo -e "$EfeitoCorAlerta Informe o domínio do painel de Audio $EfeitoFecha"
read -p 'Domínio Audio: ' dominio_painel_audio

echo -e "$EfeitoCorAlerta Informe o domínio do player de Audio $EfeitoFecha"
read -p 'Domínio Player Audio: ' dominio_painel_audio_player

echo -e "$EfeitoCorAlerta Informe o domínio para o proxy SSL(deve iniciar com ssl.   Exemplo: ssl.painel.com) $EfeitoFecha"
read -p 'Domínio Proxy SSL: ' dominio_painel_audio_proxy

echo -e "$EfeitoCorAlerta Informe a porta para SSH(Padrão: 6985) $EfeitoFecha"
read -p 'Porta SSH: ' porta_ssh

echo -e "$EfeitoCorAlerta Será configurado o SSL para $dominio_painel_audio (painel), $dominio_painel_audio_player (player) e $dominio_painel_audio_proxy (proxy) o DNS já deve estar propagado ou terá problemas na hora da instalação $EfeitoFecha"

echo
echo -e "$EfeitoCorTitulo Confirme se os dados digitados estão corretos $EfeitoFecha"
read -p 'Confirma(y/n): ' confirma

if [ "$confirma" != "${confirma#[Nn]}" ] ;then

clear

echo
echo -e "$EfeitoCorAlerta Reinicie o instalador com os dados corretos... $EfeitoFecha"
echo

exit 1

fi

if ! [[ $versao_centos == ?(-)+([7-8]) ]]; then

echo -e "$EfeitoCorAlerta Não foi possível detectar automáticamente a versão do CentOS deste servidor! Por favor informe a versão, digite: 6 OU 7 OU 8 $EfeitoFecha"
read -p 'Versão: ' versao_centos

fi

if [ -z "$porta_ssh" ]; then
porta_ssl="6985"
fi

echo
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorAlerta Salve estas informações abaixo para usar na instalação do ShoutCast: $EfeitoFecha"
echo
echo -e "$EfeitoCorAlerta Host MySQL: $dominio_painel_audio $EfeitoFecha"
echo -e "$EfeitoCorAlerta Usuário MySQL: painel $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha MySQL: $senha_painel_mysql $EfeitoFecha"
echo -e "$EfeitoCorAlerta Banco MySQL: audio $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo

read -n 1 -s -r -p "Pressione qualquer tecla para continuar com a instalação..."
echo
echo -e "$EfeitoCorOK Iniciando instalacao dos modulos... $EfeitoFecha"
echo

if [ "$1" == "--skip-inter" ] || [ "$2" == "--skip-inter" ]; then

echo
echo -e "$EfeitoCorAlerta Modo interativo desativado! $EfeitoFecha"
echo

silenciar="sim"

fi

checagem_epel=`/usr/bin/rpm -qa epel-release | wc -l`

if [ "$checagem_epel" -eq 0 ]; then

wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-$versao_centos.noarch.rpm
rpm -i epel-release-latest-$versao_centos.noarch.rpm

yum install epel-release -y

fi


yum config-manager --set-enabled PowerTools

yum install usermode wget nano mailx sendmail nmap perl rsync gcc nano openssh-server openssh-clients kernel-devel postgresql-libs fuse-curlftpfs gcc glibc.i686 glibc-devel.i686 zlib-devel.i686 ncurses-devel.i686 libX11-devel.i686 libXrender.i686 libXrandr.i686 postgresql-libs openssl-devel glibc-devel unzip git lynx net-tools sqlite-devel pure-ftpd policycoreutils-python tar tzdata -y

yum install ca-certificates -y

if ! [ -x "/usr/bin/perl" ]; then

echo
echo -e "$EfeitoCorErro Falha na instalacao de modulos essenciais, instalação cancelada, verificar logs na tela. $EfeitoFecha"
echo

exit 1
fi

cd
wget https://github.com/cassini308/Painel_Vox/blob/main/lab.tar.gz
tar -zxf lab.tar.gz
cd rar
cp -v rar unrar /usr/local/bin/

cd
git clone https://github.com/vergoh/vnstat
cd vnstat
./configure --prefix=/usr --sysconfdir=/etc && make && make install
vnstat --showconfig > /etc/vnstat.conf

sed -i '/DayFormat/d' /etc/vnstat.conf
sed -i '/MonthFormat/d' /etc/vnstat.conf
sed -i '/TopFormat/d' /etc/vnstat.conf

echo 'DayFormat    "%x"' >> /etc/vnstat.conf
echo "MonthFormat  \"%b '%y\"" >> /etc/vnstat.conf
echo 'TopFormat    "%x"' >> /etc/vnstat.conf

cp -v /root/vnstat/examples/systemd/vnstat.service /etc/systemd/system/

ln -s /usr/bin/nano /usr/bin/pico

iptables -F

echo 'SELINUX=disabled' > /etc/selinux/config
echo 'SELINUXTYPE=targeted' >> /etc/selinux/config

echo 0 > /selinux/enforce

systemctl disable firewalld
systemctl stop firewalld

semanage port -a -t ssh_port_t -p tcp 6985

perl -i -p -e "s/#Port 22/Port $porta_ssh/" /etc/ssh/sshd_config

iptables -F

service iptables save

adduser painel
adduser programetes -d /home/painel/programetes
adduser programas -d /home/painel/programas

echo "painel:$senha_ftp" | chpasswd
echo "programetes:$senha_pp" | chpasswd
echo "programas:$senha_pp" | chpasswd

echo >> /etc/bashrc
echo 'ulimit -n 4096 -u 14335 -m unlimited -d unlimited -s 8192 -c 1000000 -v unlimited 2>/dev/null' >> /etc/bashrc
echo "LS_OPTIONS='--color=tty -F -a -b -T 0 -l -h';" >> /etc/bashrc
echo 'export LS_OPTIONS;' >> /etc/bashrc
echo "alias ls='/bin/ls \$LS_OPTIONS';" >> /etc/bashrc
echo 'eval `dircolors -b`' >> /etc/bashrc
echo 'PS1="\u@\h [\w]# "' >> /etc/bashrc
echo 'export VISUAL=nano' >> /etc/bashrc

source /etc/bashrc

rm -Rf /etc/localtime
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

if [ ! "$silenciar" ]; then
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
fi

echo -e "$EfeitoCorOK Iniciando instalacao do Apache + PHP 7.2 + MariaDB $EfeitoFecha"
echo

yum install httpd mod_ssl mod_qos -y
yum install epel-release -y
yum install yum-utils -y

yum install http://rpms.remirepo.net/enterprise/remi-release-$versao_centos.rpm -y
yum-config-manager --enable remi-php72

yum install php php-mysqlnd php-pdo php-mbstring php-mcrypt php-xml php-gd php-curl php-bcmath php-common php-php-gettext php-process php-tcpdf php-tcpdf-dejavu-sans-fonts php-tidy php-pear php-devel php-pecl-zip php-pecl-ssh2 libssh2 -y

cd /usr/share/
wget https://github.com/cassini308/Painel_Vox/blob/main/MyAdmin.tar.gz
tar -zxvf MyAdmin.tar.gz
mv -f phpMyAdmin-4.9.5-all-languages phpMyAdmin

cat > /etc/httpd/conf.d/phpMyAdmin.conf << EOF

Alias /php-madm /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8
   Options Indexes FollowSymLinks MultiViews
   DirectoryIndex index.php
   AllowOverride all
   Require all granted
</Directory>

<Directory /usr/share/phpMyAdmin/setup/>
   <IfModule mod_authz_core.c>
     <RequireAny>
       Require ip 127.0.0.1
       Require ip ::1
     </RequireAny>
   </IfModule>
</Directory>

<Directory /usr/share/phpMyAdmin/libraries/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory /usr/share/phpMyAdmin/setup/lib/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory /usr/share/phpMyAdmin/setup/frames/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

EOF

cat > /etc/httpd/conf.d/php.conf << EOF
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps

DirectoryIndex index.php

<Directory />
    Options +ExecCGI +FollowSymLinks +Includes +IncludesNOEXEC +Indexes -MultiViews +SymLinksIfOwnerMatch
    AllowOverride All
</Directory>

EOF

cat > /etc/httpd/conf.d/userdir.conf << EOF
<IfModule mod_userdir.c>
    UserDir disabled
</IfModule>

<Directory "/home/*/public_html">
    Options +ExecCGI +FollowSymLinks +Includes +IncludesNOEXEC +Indexes -MultiViews +SymLinksIfOwnerMatch
    AllowOverride All
    Require method GET POST OPTIONS
</Directory>

EOF

cat > /etc/httpd/conf.d/sites.conf << EOF
NameVirtualHost *:80

<VirtualHost *:80>
    DocumentRoot /home/painel/public_html
    ServerName $dominio_painel_audio
</VirtualHost>

NameVirtualHost *:80

<VirtualHost *:80>
    DocumentRoot /home/painel/public_html/player
    ServerName $dominio_painel_audio_player
    ServerAlias player.*
</VirtualHost>

EOF

sed -i '/max_execution_time/d' /etc/php.ini
sed -i '/max_input_time/d' /etc/php.ini
sed -i '/max_input_vars/d' /etc/php.ini
sed -i '/post_max_size/d' /etc/php.ini
sed -i '/upload_max_filesize/d' /etc/php.ini
sed -i '/memory_limit/d' /etc/php.ini
sed -i '/max_file_uploads/d' /etc/php.ini
sed -i '/date.timezone/d' /etc/php.ini
sed -i '/default_charset/d' /etc/php.ini

echo '' >> /etc/php.ini
echo ';Tunning Mygles - suporte@mygles.com' >> /etc/php.ini
echo 'max_execution_time = 1800' >> /etc/php.ini
echo 'max_input_time = 1800' >> /etc/php.ini
echo 'max_input_vars = 5000' >> /etc/php.ini
echo 'post_max_size = 200M' >> /etc/php.ini
echo 'upload_max_filesize = 200M' >> /etc/php.ini
echo 'memory_limit = 1024M' >> /etc/php.ini
echo 'max_file_uploads = 200' >> /etc/php.ini
echo 'date.timezone = "America/Sao_Paulo"' >> /etc/php.ini
echo 'default_charset = "ISO-8859-1"' >> /etc/php.ini

checar_funcao_ssh=`php -m | grep -c ssh` 

if [ "$checar_funcao_ssh" -eq 0 ]; then

echo -e "$EfeitoCorErro Erro ao instalar função SSH no PHP após concluír o instalador, instale a função no PHP. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

fi

sed -i 's/AddDefaultCharset UTF-8/AddDefaultCharset iso-8859-1/' /etc/httpd/conf/httpd.conf

echo -e "$EfeitoCorOK Iniciando instalacao dos arquivos do painel e servidor de streaming $EfeitoFecha"
echo

rm -f /etc/httpd/conf.d/welcome.conf
rm -f /etc/httpd/conf.modules.d/*mpm*.conf

echo 'LoadModule mpm_worker_module modules/mod_mpm_worker.so' > /etc/httpd/conf.modules.d/00-mpm.conf

systemctl enable httpd

cat > /etc/yum.repos.d/MariaDB.repo << EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum install MariaDB-server MariaDB-client -y

systemctl start mariadb

/usr/bin/mysqladmin -u root password "$senha_root_mysql"
/usr/bin/mysqladmin -u root -h `hostname` password "$senha_root_mysql"

touch /var/lib/mysql/servidor.err
touch /var/lib/mysql/mysql-slow.log

chmod 777 /var/lib/mysql/servidor.err /var/lib/mysql/mysql-slow.log

rm -f /etc/my.cnf.d/server.cnf /etc/my.cnf.d/mysql-clients.cnf

cat > /etc/my.cnf << EOF
[mysqld]
local-infile=0
port = 3306
datadir="/var/lib/mysql"
socket=/var/lib/mysql/mysql.sock
skip-name-resolve
skip-innodb
query_cache_limit=8M
query_cache_size=128M ## 32MB for every 1GB of RAM
query_cache_type=1
max_user_connections=25000
max_connections=10000
interactive_timeout=1800
wait_timeout=1800
connect_timeout=1800
thread_cache_size=5000
key_buffer_size=512M ## 128MB for every 1GB of RAM
join_buffer_size=16M
max_connect_errors=200
max_allowed_packet=268435456
table_cache=256
sort_buffer_size=6M ## 1MB for every 1GB of RAM
read_buffer_size=6M ## 1MB for every 1GB of RAM
read_rnd_buffer_size=6M  ## 1MB for every 1GB of RAM
thread_concurrency=10 ## Number of CPUs x 2
myisam_sort_buffer_size=24M
server-id=1
collation-server=latin1_general_ci
open_files_limit=1024000
log_error=/var/lib/mysql/servidor.err
slow-query-log = 1
slow-query-log-file = /var/lib/mysql/mysql-slow.log
long_query_time = 1 
default-storage-engine = myisam
sql-mode="NO_ENGINE_SUBSTITUTION"
EOF

systemctl restart mariadb

mysql -u root -p$senha_root_mysql -e "CREATE DATABASE IF NOT EXISTS audio;GRANT ALL PRIVILEGES ON audio.* TO 'painel'@'%' IDENTIFIED BY '$senha_painel_mysql'"
mysql -u root -p$senha_root_mysql -e "DELETE FROM mysql.user WHERE Password='';DELETE FROM mysql.user WHERE Host='::1';FLUSH PRIVILEGES;"

if [ ! "$silenciar" ]; then
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
fi

echo -e "$EfeitoCorOK Iniciando instalacao do Java + Android Studio $EfeitoFecha"
echo

yum install java-1.8* -y

echo "export JAVA_HOME=/usr" >> /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile

cd /opt/
wget http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz
tar -xzf android-sdk_r23.0.2-linux.tgz
echo "export PATH=$PATH:/opt/android-sdk-linux/platforms" >> ~/.profile
echo "export PATH=$PATH:/opt/android-sdk-linux/tools" >> ~/.profile
export PATH=$PATH:/opt/android-sdk-linux/platforms
export PATH=$PATH:/opt/android-sdk-linux/tools

echo -e "$EfeitoCorAlerta Será solicitado que você aceite as licenças, digite y para aceitar. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

/opt/android-sdk-linux/tools/android update sdk --no-ui

/opt/android-sdk-linux/tools/android update sdk --no-ui

/opt/android-sdk-linux/tools/android update sdk --no-ui --all --filter "build-tools-28.0.3"

cd /opt/
wget https://dl.google.com/android/repository/android-ndk-r20-linux-x86_64.zip
unzip android-ndk-r20-linux-x86_64.zip
mv -f android-ndk-r20 android-ndk

mkdir /usr/share/httpd/.android /usr/share/httpd/.gradle
chmod 777 /usr/share/httpd/.android /usr/share/httpd/.gradle

echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

echo -e "$EfeitoCorOK Instalando os arquivos do painel de controle $EfeitoFecha"
echo

mkdir -p /home/painel/public_html

cd /home/painel/public_html
wget -q https://file.mygles.com/files/new/front/painel-audio-responsivo.zip
unzip painel-audio-responsivo.zip
rm -f painel-audio-responsivo.zip

cat <<EOT >> /home/painel/public_html/admin/inc/conecta.php
<?php
\$host = "localhost";//nome do host
\$user = "painel";//nome de usuario do mysql
\$pass = "$senha_painel_mysql"; //senha do mysql
\$bd_streaming = "audio"; //nome do banco de dados

\$conexao = mysqli_connect(\$host,\$user,\$pass);

mysqli_select_db(\$conexao,\$bd_streaming);
?>
EOT

chown painel.painel /home/painel/public_html -Rf

chmod 0755 /home/painel -Rfv

chmod 777 /home/painel/public_html/app/apps -Rf
chmod 777 /home/painel/public_html/player/cache -Rf
chmod 777 /home/painel/public_html/player/app -Rf
chmod 777 /home/painel/public_html/player -Rf
chmod 777 /home/painel/public_html/cache -Rf
chmod 777 /home/painel/public_html/temp -Rf

chmod 777 /home/painel/public_html/app/source -Rf

cp -Rfp /home/painel/public_html/app/source /home/painel/public_html/app/source_pre_compilacao
cd /home/painel/public_html/app/source_pre_compilacao
sed -i '/HASH_GRADLEW_APP/d' /home/painel/public_html/app/source_pre_compilacao/gradlew
export JAVA_HOME=/usr;export PATH=$JAVA_HOME/bin:$PATH;./gradlew assembleRelease
rm -rf /home/painel/public_html/app/source_pre_compilacao

echo
echo -e "$EfeitoCorAlerta Desconsidere erros acima. Isso é normal pois foi feito uma pré-compilação de um APP para fazer download dos modulos necessários $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

mysql -u root -p$senha_root_mysql audio < /home/painel/public_html/banco-de-dados-audio.sql
mysql -u root -p$senha_root_mysql audio -e "INSERT INTO administradores (codigo, nome, usuario, senha) VALUES (NULL, 'Administrador', 'admin', PASSWORD('$senha_admin_painel'))"
mysql -u root -p$senha_root_mysql audio -e "INSERT INTO configuracoes (dominio_cdn, dominio_padrao, codigo_servidor_atual, codigo_servidor_aacplus_atual, usar_cdn, manutencao) VALUES ('$dominio_painel_audio', '$dominio_painel_audio', '0', '0', 'nao', 'nao')"

find /home/painel/public_html -type f | xargs replace "srvstm.com" "$dominio_painel_audio" --

if [ ! "$silenciar" ]; then
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
fi

echo -e "$EfeitoCorOK Configurando o servidor de FTP para gerenciar arquivos do painel $EfeitoFecha"
echo

sed -i '/^$/d' /etc/pure-ftpd/pure-ftpd.conf
sed -i '/^[[:blank:]]*#/d;s/#.*//' /etc/pure-ftpd/pure-ftpd.conf
sed -i '/Authentication/d' /etc/pure-ftpd/pure-ftpd.conf
echo 'UnixAuthentication            yes' >> /etc/pure-ftpd/pure-ftpd.conf

if [ ! "$silenciar" ]; then
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
fi
wget -O /etc/motd https://github.com/cassini308/Painel_Vox/blob/main/motd.txt
echo -e "$EfeitoCorAlerta Finalizando ajustes $EfeitoFecha"
echo

cat <<EOT > /var/spool/cron/root
0 5 * * * /bin/rm -rfv /var/log/httpd/*-*
0 5 * * * /bin/rm -rfv /var/log/*-20*
0 5 * * * /bin/rm -rfv /var/spool/clientmqueue/*
0 */1 * * * /bin/echo -n > /var/spool/mail/root
0 */1 * * * /bin/echo -n > /var/log/httpd/access_log
0 */1 * * * /bin/echo -n > /var/log/httpd/deflate_log
0 */1 * * * /bin/echo -n > /var/log/httpd/error_log
0 3 * * * /bin/cp -f /dev/null /etc/httpd/logs/deflate_log
0 3 * * * /bin/cp -f /dev/null /etc/httpd/logs/access_log
0 3 * * * /bin/cp -f /dev/null /etc/httpd/logs/error_log
0 3 * * 0 /usr/bin/yum clean all
0 2 * * * /usr/bin/php -q /home/painel/public_html/robots/limpar-logs.php
0 3 * * 0 /usr/bin/php -q /home/painel/public_html/robots/limpar-estatisticas.php
0 2 * * 0 /usr/bin/php -q /home/painel/public_html/robots/limpar-playlists.php
*/30 * * * * /bin/nice -20 /usr/bin/php /home/painel/public_html/robots/monitor-servidores.php
*/15 * * * * /bin/nice -20 /usr/bin/php /home/painel/public_html/robots/monitor-capacidade.php
0 */1 * * * /bin/nice -20 /usr/bin/php /home/painel/public_html/robots/monitor-servidores-uso-streamings.php
*/10 * * * * /usr/bin/php /home/painel/public_html/robots/monitor-streamings-relay.php registros=0-15000
*/5 * * * * /bin/nice -20 /usr/bin/php /home/painel/public_html/robots/gerar-estatisticas-shoutcast.php registros=0-10000
* * * * * /bin/nice -20 /usr/bin/php -q /home/painel/public_html/robots/agendamentos.php registros=0-10000
*/10 * * * * /bin/nice -20 /usr/bin/php /home/painel/public_html/robots/atualizar-uso-ftp.php registros=0-10000
0 1 * * * /usr/bin/php /home/painel/public_html/robots/backup-painel-mysql.php
*/2 * * * * /home/painel/public_html/robots/monitor-vhosts-nginx.sh
0 3 * * * certbot -n renew --standalone --pre-hook='systemctl stop httpd' --post-hook='systemctl start httpd;systemctl reload nginx'
0 4 * * * /usr/bin/php -q /home/painel/public_html/robots/download-programetes-programas.php
30 4 * * * systemctl restart nginx
EOT

yum install nginx -y

systemctl stop nginx

cat <<EOT > /etc/nginx/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  50000;
    multi_accept        on;
    use                 epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log         off;
    reset_timedout_connection on;
    send_timeout 10;
    sendfile           on;
    tcp_nopush         on;
    tcp_nodelay        on;
    keepalive_timeout  120;
    keepalive_requests 100000;

include /home/painel/public_html/proxy/*.conf;
}

EOT

rm -f /etc/nginx/conf.d/default.conf

echo 'nginx       hard    nofile      1000000' >> /etc/security/limits.conf
echo 'nginx       soft    nofile      1000000' >> /etc/security/limits.conf
echo '*         hard    nofile      500000' >> /etc/security/limits.conf
echo '*         soft    nofile      500000' >> /etc/security/limits.conf

mkdir /etc/systemd/system/nginx.service.d
echo '[Service]' > /etc/systemd/system/nginx.service.d/nofile_limit.conf
echo 'LimitNOFILE=1000000' >> /etc/systemd/system/nginx.service.d/nofile_limit.conf

systemctl daemon-reload

> /home/painel/public_html/robots/monitor-vhosts-nginx.sh

cat << 'EOT' > /home/painel/public_html/robots/monitor-vhosts-nginx.sh
#!/bin/sh
# Script para montorar os vhosts do ngin para saber se precisa recarregar

monitor=`find /home/painel/public_html/proxy/ -mmin -3 -type f | wc -l`

if [ $monitor -gt 0 ]; then

/usr/sbin/nginx -s reload

echo
echo vHosts Recarregados
echo

fi
EOT

chmod 777 /home/painel/public_html/robots/monitor-vhosts-nginx.sh

mkdir /home/painel/public_html/proxy
chmod 777 /home/painel/public_html/proxy
chown painel.painel /home/painel/public_html/proxy

echo -e "$EfeitoCorAlerta Será configurado o SSL para $dominio_painel_audio (painel), $dominio_painel_audio_player (player) e $dominio_painel_audio_proxy (proxy) o DNS já deve estar propagado ou terá problemas na hora da instalação $EfeitoFecha"
echo -e "$EfeitoCorAlerta Se DNS não foi configurado ainda OU não esta propagado(pingando) não continue, espere propagar antes de continuar apartir de aqui... $EfeitoFecha"

echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
echo

systemctl stop httpd

vversao=`wget -q -O - https://github.com/cassini308/Painel_Vox/blob/main/versao.txt`

cat <<EOT > /etc/httpd/conf.d/ssl.conf
# Configurado
LoadModule ssl_module modules/mod_ssl.so

Listen 443

SSLPassPhraseDialog  builtin

SSLSessionCache         shmcb:/var/cache/mod_ssl/scache(512000)
SSLSessionCacheTimeout  300

SSLRandomSeed startup file:/dev/urandom  256
SSLRandomSeed connect builtin

SSLCryptoDevice builtin

EOT
cd
yum -y install certbot-apache

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio_player

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio_proxy


if [ -f "/etc/letsencrypt/live/$dominio_painel_audio/cert.pem" ]; then

cat <<EOT >> /etc/httpd/conf.d/$dominio_painel_audio.conf

NameVirtualHost *:443

<VirtualHost *:443>
    DocumentRoot /home/painel/public_html
    ServerName $dominio_painel_audio

    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn

    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
    SSLCertificateFile /etc/letsencrypt/live/$dominio_painel_audio/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$dominio_painel_audio/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/$dominio_painel_audio/chain.pem

    SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

</VirtualHost>

EOT

else

echo -e "$EfeitoCorErro Erro ao instalar SSL para domínio $dominio_painel_audio, verifique os logs na tela. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

fi

if [ -f "/etc/letsencrypt/live/$dominio_painel_audio/cert.pem" ]; then

cat <<EOT >> /etc/httpd/conf.d/$dominio_painel_audio_player.conf

NameVirtualHost *:443

<VirtualHost *:443>
    DocumentRoot /home/painel/public_html/player
    ServerName $dominio_painel_audio_player

    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn

    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
    SSLCertificateFile /etc/letsencrypt/live/$dominio_painel_audio_player/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$dominio_painel_audio_player/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/$dominio_painel_audio_player/chain.pem

    SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

</VirtualHost>

EOT

else

echo -e "$EfeitoCorErro Erro ao instalar SSL para domínio $dominio_painel_audio_player, verifique os logs na tela. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

fi

systemctl enable vnstat
systemctl enable pure-ftpd
systemctl enable httpd
systemctl enable crond
systemctl enable mariadb
systemctl enable nginx

systemctl restart sshd
systemctl restart vnstat
systemctl restart httpd
systemctl restart crond
systemctl restart pure-ftpd
systemctl restart mariadb
systemctl start nginx
systemctl restart sendmail

echo
echo -e "$EfeitoCorAlerta $vversao $EfeitoFecha"
echo
echo -e "$EfeitoCorAlerta Porta SSH: $porta_ssh $EfeitoFecha"
echo
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorAlerta FTP: $dominio_painel_audio $EfeitoFecha"
echo -e "$EfeitoCorAlerta Usuario FTP: painel $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha FTP: $senha_ftp $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorAlerta FTP Programetes: $dominio_painel_audio $EfeitoFecha"
echo -e "$EfeitoCorAlerta Usuario FTP: programetes $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha FTP: $senha_pp $EfeitoFecha"
echo
echo -e "$EfeitoCorAlerta FTP Programas: $dominio_painel_audio $EfeitoFecha"
echo -e "$EfeitoCorAlerta Usuario FTP: programas $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha FTP: $senha_pp $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha Root MySQL: $senha_root_mysql $EfeitoFecha"
echo -e "$EfeitoCorAlerta Usuário MySQL: painel $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha MySQL: $senha_painel_mysql $EfeitoFecha"
echo -e "$EfeitoCorAlerta Banco MySQL: audio $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorAlerta URL Painel: https://$dominio_painel_audio/admin/login $EfeitoFecha"
echo -e "$EfeitoCorAlerta Login: admin $EfeitoFecha"
echo -e "$EfeitoCorAlerta Senha: $senha_admin_painel $EfeitoFecha"
echo
echo -e "$EfeitoCorAlerta Painel Audio: /home/painel/public_html $EfeitoFecha"
echo -e "$EfeitoCorAlerta Players: /home/painel/public_html/player $EfeitoFecha"
echo -e "$EfeitoCorTitulo ######################################################## $EfeitoFecha"
echo -e "$EfeitoCorOK Agora você deve fazer envio dos arquivos atuais do seu painel de controle. $EfeitoFecha"
echo
echo -e "$EfeitoCorOK Instalacao do servidor concluida. $EfeitoFecha"
echo
echo

fi

if [ x`echo "$1 $2" | grep -c "\-\-ssl"` = x1 ]; then

echo -e "$EfeitoCorAlerta Informe o domínio do painel de Audio $EfeitoFecha"
read -p 'Domínio Audio: ' dominio_painel_audio

echo -e "$EfeitoCorAlerta Informe o domínio do player de Audio $EfeitoFecha"
read -p 'Domínio Player Audio: ' dominio_painel_audio_player

echo -e "$EfeitoCorAlerta Informe o domínio para o proxy SSL(deve iniciar com ssl.   Exemplo: ssl.painel.com) $EfeitoFecha"
read -p 'Domínio Proxy SSL: ' dominio_painel_audio_proxy

echo -e "$EfeitoCorAlerta Será configurado o SSL para $dominio_painel_audio (painel), $dominio_painel_audio_player (player) e $dominio_painel_audio_proxy (proxy) o DNS já deve estar propagado ou terá problemas na hora da instalação $EfeitoFecha"

echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
echo

systemctl stop httpd

vversao=`wget -q -O - https://github.com/cassini308/Painel_Vox/blob/main/versao.txt`

cat <<EOT > /etc/httpd/conf.d/ssl.conf
# Configurado
LoadModule ssl_module modules/mod_ssl.so

Listen 443

SSLPassPhraseDialog  builtin

SSLSessionCache         shmcb:/var/cache/mod_ssl/scache(512000)
SSLSessionCacheTimeout  300

SSLRandomSeed startup file:/dev/urandom  256
SSLRandomSeed connect builtin

SSLCryptoDevice builtin

EOT

cd
wget https://dl.eff.org/certbot-auto
mv certbot-auto certbot
chmod a+x certbot

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio_player

certbot -n --agree-tos --register-unsafely-without-email certonly --standalone -d $dominio_painel_audio_proxy

if [ -f "/etc/letsencrypt/live/$dominio_painel_audio/cert.pem" ]; then

cat <<EOT >> /etc/httpd/conf.d/$dominio_painel_audio.conf

NameVirtualHost *:443

<VirtualHost *:443>
    DocumentRoot /home/painel/public_html
    ServerName $dominio_painel_audio

    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn

    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
    SSLCertificateFile /etc/letsencrypt/live/$dominio_painel_audio/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$dominio_painel_audio/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/$dominio_painel_audio/chain.pem

    SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

</VirtualHost>

EOT

else

echo -e "$EfeitoCorErro Erro ao instalar SSL para domínio $dominio_painel_audio, verifique os logs na tela. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

fi

if [ -f "/etc/letsencrypt/live/$dominio_painel_audio/cert.pem" ]; then

cat <<EOT >> /etc/httpd/conf.d/$dominio_painel_audio_player.conf

NameVirtualHost *:443

<VirtualHost *:443>
    DocumentRoot /home/painel/public_html/player
    ServerName $dominio_painel_audio_player

    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn

    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
    SSLCertificateFile /etc/letsencrypt/live/$dominio_painel_audio_player/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$dominio_painel_audio_player/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/$dominio_painel_audio_player/chain.pem

    SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

</VirtualHost>

EOT

else

echo -e "$EfeitoCorErro Erro ao instalar SSL para domínio $dominio_painel_audio_player, verifique os logs na tela. $EfeitoFecha"
echo
read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

fi

systemctl restart httpd

echo
echo -e "$EfeitoCorOK Instalação concluída! $EfeitoFecha"
echo

fi