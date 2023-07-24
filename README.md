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
--------- comando 2
VPS Painel:
1° Passo: Baixe os arquivos do painel em https://drive.google.com/file/d/1E75_y6aXsRn32l7xDQGu0yT-ezvcu-BO/view?usp=drive_link
2° Passo: Baixe o sh https://github.com/cassini308/Painel_Vox/blob/main/panel%20(1).sh e edite a linha: 464 (Será necessario colocar os arquivos do painel em um local onde o vps do painel poderá dar um wget. 
3° atualize e baixe o sh para sua VPS:
4° Passo
chmod +x panel.sh
sed -i -e 's/\r$//' panel.sh
sh panel.sh



Caso queira fazer uma doação, segue a chave PIX: a26e28c1-4601-4e72-b79c-710f7781d3e3
