####################################################
# Coruja Feed Parser v0.1                          #
#                                                  #
# Grupo de Resposta a Incidentes de Seguran�a      #
# Departamento de Ci�ncia da Computa��o            #
# Universidade Federal do Rio de Janeiro           #
#                                                  #
#                                                  #
# Authors:                                         #
#          Rodrigo M. T. Fernandez                 #
#                                                  #
# License:                                         #
#          Open Source                             #
#                                                  #
#               www.gris.dcc.ufrj.br               #
####################################################

Developed to help sysadmins to follow vulnerabilities RSS feeds. Based on a key word list, it parses multiple feeds, to build a compilation of information containing only what matters to the sysadmin.

Current version: v0.1-rc1

Changelog:

    * v.0.1:
          o Busca por tags <item> e </item> selecionando o que h� entre elas quando uma word da wordlist � encontrada entre elas 
          o Retorna um txt contendo o conteudo selecionado

    * v 0.2 (implementar):
          o Verificar vers�o do RSS Feed que est� sendo checado
                + verify if links are valid XML resources before performing any actions 
          o use tag # for comments in input files and ignore blank lines
          o Testar se no feed existe alguma pattern da wordlist mas n�o existe as tags <item> e </item>
          o Gerar sa�da em HTML/XML
          o Para cada pattern da wordlist, fazer uma combina��o de poss�veis varia��es e us�-las para identificar aquela pattern dentro do feed 

    * v 0.3 (implementar):
          o Aprovar ou negar as entradas do linklist e da wordlist (prote��o) 

    * v 0.4 (implementar):
          o Incluir leitura de feeds no formato ATOM (http://tools.ietf.org/html/rfc4287) 
