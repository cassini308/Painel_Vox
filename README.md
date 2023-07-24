# Painel_Vox
Painel VoxStream Atualizado - Versão com SSl, Site Administravel e App Multi Plataforma e Instalador Automático.

 Instalação depende de 2 VPS, sendo um para o painel e outro para o ShoutCast.
 Painel possui erros que devem ser corrigidos.

 Em ambos VPS, executar o seguinte comando:
 --- comando 1

echo 'SELINUX=disabled' > /etc/selinux/config
echo 'SELINUXTYPE=targeted' >> /etc/selinux/config
echo 0 > /sys/fs/selinux/enforce
reboot

Após inicie normalmente o instalador. 

Caso queira fazer uma doação, segue a chave PIX: a26e28c1-4601-4e72-b79c-710f7781d3e3
