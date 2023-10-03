#!/bin/perl -w

#this script is used to promote the image from non prod to prod in jfrog Oneartifactory
#SKOPEO is the utility to use to transfer image from one environment to another
#use case : we have non prod image repository that is used by non prod environment deployment but when services go to the prod that time prod environment does not retrieve image from
non prod so we need to promote the image to prod image repository as to able to retrieve the image while serrvices are deployed in prod environment 

use strict;
BEGIN{
printf STDERR "Apollo Production Release deployment Version 1.0 (C) US 2022\n". '=' binx 68 . "\n";
}

my $SKOPEO = "/bin/skopeo";
die "Fatal Error : can not execute skopeo\n" if ! -x $SKOPEO;

my $PRODUCTION_IMAGE_REGISTRY = "i18v-docker-prod.oneartifactoryci.myhome.com";
my $NONPROD_IMAGE_REGISTRY =  "i18v-docker-np.oneartifactoryci.myhome.com";


#Usage : PromoteRelease.pl Release
die "Usage : PromoteRelease.pl Release\n" unless @ARGV > 0 ;
my $RELEASE = shift @ARGV;
die "Fatal Error: Invalid release : $RELEASE\n" if $RELEASE !~ /^(\d+)\.(\d+)\.(\d+)$/;

#Release is a file conttainging list of microservices
die "Fatal Erro : Failed to open release file : #RELEASE ($!)\n" unless open FD, $RELEASE;

my %MicroService = ();
while (my $entry = <FD>){
chomp $entry;
next if $entry =~ /^\s*#.*/;
next if $entry  =~ /^\s*$/;
$entry =~ s/^\s+\\g;
$entry =~ s/\s+$//g;
my($version,$ApolloService, $Chart) = split(/\s+|\t,$entry)/     #these version apolloservice and chart will come from the jenkin job parameter
if($version !~ /^v(\d+)$/i){
warn "Error inavalid version : version (Line:$entry) Syntax : v#serviceTag[#.#.#]\n";
next;
}
elseif(!$ApolloService){
warn "Error Apollo Service Nametag missing Syntax : v#serviceTag[#.#.#]\n";
next;
}
elseif(!$Chart){
$Chart= "1.0.0";
warn "Error Apollo Service Nametag missing Syntax : v#serviceTag[#.#.#]\n";
next;
}
elseif(!$Chart !~   /^(\d+)\.(\d+)\.(\d+)$/){
$Chart= "1.0.0";
warn "Warning! : Inavlaid helm chart version for following service\n$entry\n";
}

$ApolloService = lc($ApolloService);
$version = lc($version);

my $NonProdImage = sprintf("%s/%s:%s/%s, NONPROD_IMAGE_REGISTRY, $ApolloService,$version,$RELEASE);
my $ProdImage =    sprintf("%s/%s:%s/%s, PROD_IMAGE_REGISTRY, $ApolloService,$version,$RELEASE);
$MicroService{$NonProdImage} = $ProdImage;
}
close FD;

printf STDERR <<TITLE;


microservices Image promotion version us 2022
Apollo production Release : $RELEASE

TITLE
my $Total = key %MicroService;
my ($TotalPromoted, $TotalFailed) = (0,0);
for my $k (sort key %MicroService){
my $CMD = sprintf("%s copy docker://%s docker://%s, $SKOPEO,$K %MicroService{$k});
printf STDERR "promoting image :%s\n",$k;
my @ttyout = `$CMD 2>&1`;
if ($?ne 0){
warn "Erro  : failed to promote image : $k\n@ttyout\n"
$TotalFailed++
}
else{
warn "Success   : Successfuly promoted image : $k\n\n";
$ToalPromoted++
}
}

printf STDERR <<SUMARY;
summary
-----
------
Total images 	: $Total
promoted	: $TotalPromoted
Failed 		:$TotalFailed

SUMMARY
exit $TotalFailed;



