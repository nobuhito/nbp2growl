#!/opt/local/bin/perl
 
use strict;
use warnings;
use Web::Scraper;
use URI;
use YAML;
use Net::Growl;
use File::HomeDir;
use Storable qw/nstore retrieve/;
use utf8;
 
my $app = 'nbp2growl';
 
my $config_file = File::HomeDir->my_home . '/.'.$app.'.yaml';
my $config = YAML::LoadFile($config_file) || {};
 
my $cache_file = File::HomeDir->my_home . '/.'.$app.'.cache';

# 好みのチームのページへ
my $url = 'http://www.nikkansports.com/baseball/professional/team/ti-team.html';
my $uri = URI->new($url);
 
my $xpath_root = '/html/body/div[2]/div[5]/div/div[2]/div/div[2]/div';
 
my $scraper = scraper {
 process $xpath_root,
   'list[]' => scraper {
     process '//table/tr/td[@class="team"]', 'team[]' => 'TEXT';
     process '//table/tr/td[@class="totalScore"]','score[]' => 'TEXT';
   };
 process $xpath_root.'/h5', 'description' => 'TEXT';
 # Icon表示用にスクレイプできるがNet::Growlでは表示できないうえ、
 # そもそもGifファイルなので表示が汚い
 # my $img_xpath =
 # '/html/body/div[2]/div[5]/div/div[2]/div/div[3]/div[2]/dl/dt/img'
 # process $xpath_root.$img_xpath, 'img' => '@src';
};
my $result = $scraper->scrape($uri);
 
my $cache = (-e $cache_file) ? retrieve $cache_file
                             : {description => ""};
 
my $list = $result->{list}->[0];
if ($cache->{description} ne $result->{description}) {
  register(
    application => $app,
    host        => $config->{growl}->{host},
    password    => $config->{growl}->{pass},
  );
 
  my $title  = $list->{team}->[0] . " " . $list->{score}->[0];
     $title .= " - ";
     $title .= $list->{score}->[1] . " " . $list->{team}->[1];
 
  notify(
    application => $app,
    password    => $config->{growl}->{pass},
    title       => $title,
    description => $result->{description},
  );
}
 
nstore $result, $cache_file;
