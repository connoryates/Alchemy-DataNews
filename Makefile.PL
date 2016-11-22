use strict;
use warnings;
 
use 5.008;
 
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME           => 'Alchemy-DataNews',
  VERSION_FROM   => 'lib/Alchemy/DataNews.pm',
  BUILD_REQUIRES => {
    'Test::More' => '0.47',
  },
);
