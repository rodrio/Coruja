#!/usr/bin/perl -w


use strict;
use HTTP::Lite;
use Net::SMTP;

# Variaveis de configuracao
my $url="http://www.zone-h.org/index.php?option=com_attacks&Itemid=45&filter=1"; # URL a ser monitorada
#my $filtro='.br'; # Filtro a ser usado no POST
my $filtro=$ARGV[0];
my $source ='monitor@gris.dcc.ufrj.br'; # Enviando email de...
my $dest ='gris@gris.dcc.ufrj.br'; # Enviando email para...
my $smtp = Net::SMTP->new('localhost'); #Objeto do Net::SMTP (servidor SMTP entre parenteses)

# Variaveis gerais
my $http; #Objeto do modulo HTTP::Lite
my %vars; #Variaveis de POST a serem enviadas
my $req; #Guarda o resultado da operação GET/POST (Ex: 200 significa OK)
my $body; #Guarda o HTML já filtrado (guarda a parte que interessa)
my @linhas; #Guarda o conteudo de $body separado em linhas
my $position1; #Guarda a posição da primeira peculiaridade
my $position2; #Guarda a posição da segunda peculiaridade
my $data; #recebe o valor da data do ataque
my $hacker; #recebe o valor do grupo hacker
my $defaced; #recebe o valor da url comprometida
my $i=0; #contador
my $j=0; #contador
my $char = ""; # Auxilia na manipulaçao das strings
my $resultado; # Dado final a ser anexado ao relatorio diario.
my $arquivo;  # Auxiliar para abrir o arquivo de relatorio


# //INICIO DAS SUBROTINAS
#
# Escreve arquivo de log
sub Logger{
	my @date = localtime();
	my @msg = @_;
	open (LOG, ">>log.txt") or die "Erro ao abrir o arquivo: $!";
	print LOG "$date[3]/$date[4]/$date[5] $date[2]:$date[1]:$date[0] - $msg[0]\n";
	close LOG;
}

# Envia o email de notificação
sub Mailing{
	$smtp->mail($source) or die "Não foi possível enviar o email: $!";
	$smtp->to($dest);
	$smtp->data();
	$smtp->datasend("From: $source\n");
	$smtp->datasend("To: $dest\n");
	$smtp->datasend("Subject: ZONE-H: Defacement na UFRJ\n");
	$smtp->datasend("\n");
	$smtp->datasend("$resultado\n\n\n");
	$smtp->dataend();
	$smtp->quit;
	Logger("Email enviado");
}

# Sinaliza o fim do programa (utilizado quando o Zone-H encontra-se Offline)
sub End {
Logger("OFFLINE ou SEM RESULTADOS");
exit;
}
#
# //FIM DAS SUBROTINAS


# CONTROLANDO O FILTRO
Logger("Realizando o controle do filtro inputado");
if ($filtro =~ /org/ or $filtro =~ /zone/){
	Logger("O FILTRO NAO PODE CONTER NEM 'ORG' NEM 'ZONE'");
	exit;
}

# FAZENDO O REQUEST E RECEBENDO O HTML
	$http = new HTTP::Lite;
	%vars = (
		"filter_domain" => $filtro,
	);
	$http->prepare_post(\%vars);
	$req = $http->request("$url") or die "Não foi possível acessar a url: $url\nMotivo: $!";
Logger("Requisitando URL");

# REALIZANDO CONTROLE DO BLOCO HTML

	if ($http->body() !~ /\<\!-- DEFACEMENTS ROWS --\>/){
		if($http->body() !~ /Offline/ && $http->body() !~ /No results/){
			# Nao possui mais a peculiaridade necessaria
			$resultado = "A URL a ser monitorada encontra-se sem as peculiaridades necessárias para separar blocos HTML. Neste caso, a tag nao encontrada foi:\n<!-- DEFACEMENTS ROWS -->\n\nNao foi possivel realizar o monitoramento.\n";
#			Mailing();
			Logger("A URL a ser monitorada encontra-se sem as peculiaridades necessárias para separar blocos HTML");
		}else{
			End();
		}
	}
	if ($http->body() !~ /\<\!-- DISCLAIMER FOOTER --\>/){
		if($http->body() !~ /Offline/ && $http->body() !~ /No results/){
			# Nao possui mais a peculiaridade necessaria
			$resultado = "A URL a ser monitorada encontra-se sem as peculiaridades necessárias para separar blocos HTML. Neste caso, a tag nao encontrada foi:\n<!-- DISCLAIMER FOOTER -->\n\nNao foi possivel realizar o monitoramento.\n";
#			Mailing();
			Logger("A URL a ser monitorada encontra-se sem as peculiaridades necessárias para separar blocos HTML");
		}else{
			End();
		}
	}

# TRATANDO O CODIGO HTML
	$position1 = index($http->body(), '<!-- DEFACEMENTS ROWS -->');
	$position2 = index($http->body(), '<!-- DISCLAIMER FOOTER -->');

	$body = substr($http->body(), $position1, $position2-$position1);

	@linhas = split("<tr>", $body);
	Logger("Tratando o código HTML");


# ABRE O ARQUIVO DE RELATORIO DIARIO
open (LEITURA, "<relatorio.txt") or die "Erro ao abrir o arquivo: $!";
foreach (<LEITURA>){
  $arquivo .= $_;
}
Logger("Lendo o arquivo de relatório");
close LEITURA;


# A cada ocorrencia separa a data, o hacker e a url comprometida
# Utiliza expressao regular para achar os dados

	foreach(@linhas){
		if(/zone-h/){
			# Pegando a data...
			if(/\s\d{4}\/\d{2}\/\d{2}\s/){
				$data = substr($_, index($_, '/')-4, 10);
				Logger("Detectado data");
			}else{
				$data = 'nao encontrado' 
			}

			# Pegando o hacker
			if(/defacer/){
				$i = 0;
				$char = "";
				while($char !~ /\//){
					$i++;
					$char = substr($_, index($_, 'defacer')+8+$i, 1);
				}
				$hacker = substr($_, index($_, 'defacer')+8, $i);
				Logger("Detectado hacker");
			}else{
				$hacker = 'nao encontrado' 
			}

			# Pegando a url comprometida
			if(/$filtro/){
				# achando o lenght (pra tras) até a string 'http'
				$i=0;
				$char = "";
				while($char !~ /http/){
					$i++;
					$char = substr($_, index($_, $filtro)-$i, 4);
				}
				# achando o lenght (pra frente) até o caracter '"'
				$j=0;
				$char = "";
				while($char !~ /\"/){
					$j++;
					$char = substr($_, index($_, $filtro)+$j, +1);
				}
				$defaced = substr($_, index($_, $filtro)-$i, $i+$j);
				Logger("Detectado defaced");
			}

			$resultado = "\nDATA: $data\nDEFACED: $defaced\nHACKER: $hacker (http://www.zone-h.org/component/option,com_attacks/Itemid,45/filter_defacer,$hacker/)\n\n______________";

			# Testa se ja existe o registro. Caso contrario escreve o novo registro no fim do arquivo  
			unless ($arquivo =~ /$defaced/){
				Logger("Escrevendo no relatorio do defacement detectado");
				open (ESCRITA, ">>relatorio.txt") or die "Erro ao abrir o arquivo: $!";
				print ESCRITA "$resultado\n";
				close ESCRITA;
				if($defaced =~ /\.ufrj\.br/){
					Logger("Defacement na UFRJ detectado, enviando email");
					Mailing();
				}
			}
		}
	}

Logger("Finalizado\n");
