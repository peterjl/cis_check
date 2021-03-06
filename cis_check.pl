#!/usr/bin/perl
use warnings;
use strict;
use List::Util qw(sum);
use WWW::Mechanize;
use Getopt::Long;
use Term::ReadPassword;
binmode(STDOUT, ":utf8");
#####################################
# INITIALIZE
#####################################
my ($password, $username, $realname, $nakmail) = "";
my ($verbose, $validate, $devmode) = 0; # Command line options
GetOptions ('verbose' => \$verbose, 'validate' => \$validate, 'password=s' => \$password, 'username=s' => \$username, 'devmode' => \$devmode);
my (%examsCredit, %examsGrade) = ();
# %examsCredit: Key: exam name, Value: cp
# %examsGrade: Key: exam name, Value: grade 
my @sanitizeMe;
$password = read_password('Enter password: ') if ($devmode);
print "Initialize WebAgent...\n" if ($verbose);
my $mech = WWW::Mechanize->new();
$mech -> cookie_jar(HTTP::Cookies->new());
#####################################
# MAIN
#####################################
print "Loading CIS...\n" if ($verbose);
$mech->get( "https://cis.nordakademie.de/startseite/" );
$mech -> field ('user' => $username);
$mech -> field ('pass' => $password);
print "Trying to login...\n" if ($verbose);
$mech -> submit();
exit(0) if ($validate);
print "Fetching results...\n" if ($verbose);
# Get data and regex pairs into hash map:
$mech->get( "https://cis.nordakademie.de/pruefungsamt/pruefungsergebnisse/" );
@sanitizeMe = $mech->content =~ /450><p class='noten_noten'>(.*?)<.*?value='([1-5]\.[0-7])/sg;
($realname) = $mech->content  =~ /als <b>(.+?)</s;
$mech->get( "https://cis.nordakademie.de/nacommunity/mein-profil/" );
($nakmail) = $mech->content =~ />(.+?@.+?)</;
# Unfortunately the exam names differ, e.g. "Programmierung1" vs. "Programmierung 1"
for (my $i=0; $i <= $#sanitizeMe; $i++)
{
	$sanitizeMe[$i] =~ s/(\S)([1-2])/$1 $2/;
}
%examsGrade = @sanitizeMe;
$mech->get( "https://cis.nordakademie.de/pruefungsamt/studienplan/" );
%examsCredit = $mech->content =~ /g'>&nbsp;&nbsp;(.*?)<\/td>.*?cp.*?<span>([1-9])</g;
print "Hallo, $realname ($nakmail)!\n";
printf("Dein simpler Durchschnitt liegt bei: %.3f!\nBisher wurden %d Klausuren geschrieben.\n\nDeine Noten im Detail:\n\n", sum(values(%examsGrade)) / keys( %examsGrade ), keys( %examsGrade )+0);
printf "%-56s %-12s %s\n", "Fach:", "Note:", "Credits:";
my $averageRaw = 0;
my $totalCredits = 0;
foreach my $gradeKey ( keys %examsGrade )
{
	my $credit = 0;
	if (exists $examsCredit{$gradeKey})
	{	
		$credit = $examsCredit{$gradeKey};
	}
	unless ($examsGrade{$gradeKey} > 4.0)
	{
	$averageRaw = $averageRaw + $examsGrade{$gradeKey} * $credit;
	$totalCredits = $totalCredits + $credit;
	#print "Aktueller Rohdurchschnitt: $averageRaw Credits total: $totalCredits\n" if($verbose);
	}
	printf "%-56s %-12.1f %d\n", $gradeKey, $examsGrade{$gradeKey},$credit;
}
my $average = $averageRaw / $totalCredits;
print "\nDein gewichteter Durchschnit: $average \n";

