#!/bin/perl -w

use strict;
use Cwd;


BEGIN{
 print STDERR "Apollo production release deployment version 1.0 \n". '=' x 68 . "\n";
}

my $HELM = "/usr/local/bin/helm";
die "Fatal error: can not execute helm\n" if ! -x $HELM;
my $PROD_HELM_REGISTRY = "I18V_Apollo_Prod_charts-prod";

#Usage: Deployment.pl Release
die "Usage : $0 release (prod|dr) \n" unless @ARGV > 0;
my $RELEASE = shift @ARGV;
die "Fatal error: Invalid release : $RELEASE\n" if ! -f $RELEASE !~ /^(\d+)\.(\d+)\.(\d+)$/;
die "Fatal error: can not deploy release : $RELEASE\n" if ! -f $RELEASE || ! -r $RELEASE;

my $Release_Environment = shift @ARGV;
die "Fatal Error : can not deploy Release environment prod or dr is not specified\n" if ! defined $Release_Environment;
if($Release_Environment=~/^(prod|production)$/i){
$Release_Environment="prod";
}
elsif($Release_Environment=~/^dr$/i){
$Release_Environment="dr";
}
else{
die "Fatal Error : Invalid environment $Release_Environment (must be prod or dr )\n";
}

#initializing helm configuration on fly
warn "adding helm configuration ....\n";
$ENV{XDG_CONFIG_HOME} = ".config";
$ENV{XDG_CACHE_HOME} = ".cache";
$ENV{XDG_DATA_HOME} = ".data";

die "Fatal Error : can not access kubeconfig configuration/n" if ! -r ".kubeconfig";
$ENV{KUBECONFIG}= "./.kubeconfig";

#helm config directory
my @ttyout = `mkdir -p $ENV{XDG_CONFIG_HOME}/helm` if ! -d $ENV{XDG_CONFIG_HOME}/helm";
die "Fatal Error : @ttyout\n" if ! -d $ENV{XDG_CONFIG_HOME}/helm";

#helm repository configuration
die "Fatal Error : failed to add help repository configuration ($!)\n" unless open FD, "> $ENV{XDG_CONFIG_HOME}/helm/repositories.yaml";
print FD <DATA>;
close FD;


#helm cache and data directories
@ttyout= `mkdir -p $ENV{XDG_CACHE_HOME}` if ! -d `mkdir $ENV{XDG_CACHE_HOME};
die "Fatal Erro : @ttyout\n" if ! -d $ENV{XDG_CACHE_HOME};
@ttyout = `mkdir -p $ENV{XDG_DATA_HOME}` if ! -d `mkdir $ENV{XDG_DATA_HOME};
die "Fatal Erro : @ttyout\n" if ! -d $ENV{XDG_DATA_HOME};

#UPDATE HELM LOCAL REPO LIST
@ttyout=`$HELM repo update`;
print @ttyout;

warn "\nChecking Apollo microservices helm charts .....\n";

#release is a file containing a list of microservices
die "Fatal Error: Failed to open Release file: $RELEASE ($!)\n" unless open FD, $RELEASE;
my $cmd;
my %Batch = ();
my $nameTag;
my($TotalCharts, $TotalServices)= (0,0);
my $DeployStatus = ();
while (my $entry = <FD>){
chomp $entry;
$entry =~/^\s+|\s+$//g;
next if $entry = /^$|^#/;
my($version,$ApolloServices,$Chart)=split(/\s+|\t/,$entry);
if ($version !~ /^v(\d+)$/i){
warn "Error apollo service nametag missing (Line: $entry) syntax: v#ServiceTag [#.#.#]\n";
next;
}
elsif (!$chart){
$chart= "1.0.0";
}
elsif($chart !~ /^(d\+).(\d+).(\d+)/){
warn "Error invalid helm chart version  (Line: $entry) syntax: v#ServiceTag [#.#.#]\n";
next;
}

$version = lc($version);
$NameTag = lc($ApolloService);
$TotalServices++;

$cmd = "$HELM show chart $PROD_HELM_REGISTRY/$ApolloService-dr -- version $Chart";
`$cmd >/dev/null 2>$1`;
if($?){
warn " warning : Helm chart $PROD_HELM_REGISTRY/$ApolloService:$Chart missing in registry\n";
$DeployStatus{ApollosService}="Helm chart missing";
next;
}
else{
$TotalCharts++;
}

$cmd = "$HELM upgrade --install "
       . "--namespace i18v-prod-apollo "
       . "--set k8s.NameSpace=i18v-prod-apollo "
       . "--set Apollo.Microservice.Image.buildNumber=$Release "
       . "--set Apollo.Microservice.version=$version "
       . "--set Apollo.MicroService.Environment=prod "
       . "v1-$nameTag-prod "
       . "$PROD_HELM_REGISTRY/$ApolloService-$Release_Environment";
  printf "%s\n, $cmd;
$Batch{$ApolloService}=$cmd;
}
close FD;

#terminate if there are no valid helm charts for deployment
die "/n/n/Fatal Error: there are no valid helm charts in the Helm repository to deploy services\n" if $TotalCharts==0;
printf STDERR ,<<TITLE;

Total services in release : 	$TotalServices
Total HElm charts :		$TotalCharts
------------------------------------------
------------------------------------------

TITLE

my $Total = key %Batch;
my ($TotalDeployed, $TotalFailed) = (0,0);


for my $k (sort keys %Batch){
   printf "/nMicroService: %s\n", $k;
   my@ttyout = `$Batch{$k} 2>&1`;
   if($?){
        $TotalFailed++;
        $DeployStatus{$k}="Failed";
  }
   else{
   $TotalDeployed++;
   $DeployStatus{$k} = "Deployed";
}
  print @ttyout;
}

print STDERR << SUMMARY;

summary
-------
Total services in release	:$TotalServices
Total Helm Charts 		:$TotalCharts
Total Services Deployed		:$TotalDeployed
Failed				:$TotalFailed

SUMMARY

for my $k (sort keys %DeployStatus){
  printf "%-15s %s\n", $DeployStatus{$k},$k;
}
  exit $TotalFailed;



_DATA_
apiVersion: ""
















