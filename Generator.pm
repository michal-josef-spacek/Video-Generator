package Video::Generator;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use FFmpeg::Command;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use IO::CaptureOutput qw(capture_exec);
use Image::Random;
use Readonly;
use Video::Delay::Const;
use Video::Pattern;

# Constants.
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Delay generator.
	$self->{'delay_generator'} = undef;

	# Duration.
	$self->{'duration'} = 10000;

	# Frames per second.
	$self->{'fps'} = 60;

	# Image generator.
	$self->{'image_generator'} = undef;

	# Image type.
	$self->{'image_type'} = 'bmp';

	# Temporary dir.
	$self->{'temp_dir'} = undef;

	# Verbose mode.
	$self->{'verbose'} = 0;

	# Video pattern generator.
	$self->{'video_pattern'} = undef;

	# Sizes.
	$self->{'height'} = 1080;
	$self->{'width'} = 1920;

	# Process params.
	set_params($self, @params);

	# Temporary directory.
	if (! defined $self->{'temp_dir'}) {
		$self->{'temp_dir'} = tempdir();
	}

	# Image generator.
	if (! defined $self->{'image_generator'}) {
		$self->{'image_generator'} = Image::Random->new(
			'height' => $self->{'height'},
			'type' => $self->{'image_type'},
			'width' => $self->{'width'},
		);
	}

	# Delay generator.
	if (! defined $self->{'delay_generator'}) {
		$self->{'delay_generator'} = Video::Delay::Const->new(
			'const' => 1000,
		);
	}

	# Video pattern generator.
	if (! defined $self->{'video_pattern'}) {
		$self->{'video_pattern'} = Video::Pattern->new(
			'delay_generator' => $self->{'delay_generator'},
			'duration' => $self->{'duration'},
			'fps' => $self->{'fps'},
			'image_generator' => $self->{'image_generator'},
		);
	}

	# Object.
	return $self;
}

# Create random video.
sub create {
	my ($self, $out_path) = @_;

	# Create images.
	$self->{'video_pattern'}->create($self->{'temp_dir'});
	if ($self->{'verbose'}) {
		print "Video pattern generator created images for video in ".
			"temporary directory.\n";
	}

	# Create video.
	my $ffmpeg = FFmpeg::Command->new;
	my $images_path = catfile($self->{'temp_dir'},
		'%03d.'.$self->{'image_type'});
	my @command_options = ('-loglevel', 'error', '-r', $self->{'fps'},
		'-i', $images_path, $out_path);
	$ffmpeg->options(@command_options);
	$ffmpeg->exec;
	if ($ffmpeg->stderr) {
		my @stderr = split m/\n/ms, $ffmpeg->stderr;
		my $command = join $SPACE, @command_options;
		err "Error with command 'ffmpeg $command'.",
			map { ('STDERR', $_) } @stderr;
	}
	if ($self->{'verbose'}) {
		print "Created video file.\n";
	}

	# Remove temporary directory.
	rmtree $self->{'temp_dir'};
	if ($self->{'verbose'}) {
		print "Removed temporary directory.\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Video::Generator - Perl class for video generation.

=head1 SYNOPSIS

 use Video::Generator;
 my $obj = Video::Generator->new(%parameters);
 my $type = $obj->create($out_path);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<delay_generator>

 Delay generator.
 Default value is object below:
   Video::Delay::Const->new(
           'const' => 1000,
   )

=item * C<duration>

 Video duration used for implicit 'video_pattern' parameter.
 Possible suffixes are:
 - ms for milisendons.
 - s for seconds.
 - min for minute.
 - h for hour.
 Default value is 10000 (10s).

=item * C<fps>

 Frames per second.
 Default value is 60.

=item * C<height>

 Height.
 Default value is 1080.

=item * C<image_generator>

 Image generator.
 Default value is object below:
   Image::Random->new(
           'height' => $self->{'height'},
           'type' => $self->{'image_type'},
           'width' => $self->{'width'},
   )

=item * C<image_type>

 Image type used for implicit 'image_generator' parameter.
 List of supported types: bmp, gif, jpeg, png, pnm, raw, sgi, tga, tiff.
 Defult image type is 'bmp'.

=item * C<temp_dir>

 Temporary dir.
 Default value is File::Temp::tempdir().

=item * C<verbose>

 Verbose mode.
 Default value is 0.

=item * C<video_pattern>

 Video pattern generator.
 Default value is object below:
   Video::Pattern->new(
           'delay_generator' => $self->{'delay_generator'},
           'duration' => $self->{'duration'},
           'fps' => $self->{'fps'},
           'image_generator' => $self->{'image_generator'},
   )

=item * C<width>

 Width.
 Default value is 1920.

=back

=item C<create($out_path)>

 Create video.
 Returns undef.

=back

=head1 ERRORS

 new():
         From Class::Utils:
                 Unknown parameter '%s'.
         From Image::Random:
                 Image type '%s' doesn't supported.
         From Video::Pattern:
                 Parameter 'duration' must be numeric value or numeric value with time suffix.
                 Parameter 'fps' must be numeric value.

 create():
         Error with command '%s'.
                 STDERR, %s
                 ..

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use File::Path qw(rmtree);
 use File::Spec::Functions qw(catfile);
 use File::Temp qw(tempdir);
 use Video::Generator;

 # Temporary directory.
 my $temp_dir = tempdir();

 # Object.
 my $obj = Video::Generator->new;

 # Create video.
 my $video_file = catfile($temp_dir, 'foo.mpg');
 $obj->create($video_file);

 # Print out type.
 system "ffprobe -hide_banner $video_file";

 # Clean.
 rmtree $temp_dir;

 # Output:
 # Input #0, mpeg, from '/tmp/GoCCk50JSO/foo.mpg':
 #   Duration: 00:00:09.98, start: 0.516667, bitrate: 1626 kb/s
 #     Stream #0:0[0x1e0]: Video: mpeg1video, yuv420p(tv), 1920x1080 [SAR 1:1 DAR 16:9], 104857 kb/s, 60 fps, 60 tbr, 90k tbn, 60 tbc

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use File::Path qw(rmtree);
 use File::Spec::Functions qw(catfile);
 use File::Temp qw(tempdir);
 use Video::Generator;

 # Temporary directory.
 my $temp_dir = tempdir();

 # Object.
 my $obj = Video::Generator->new(
         'verbose' => 1,
 );

 # Create video.
 my $video_file = catfile($temp_dir, 'foo.mpg');
 $obj->create($video_file);

 # Clean.
 rmtree $temp_dir;

 # Output:
 # Video pattern generator created images for video in temporary directory.
 # Created video file.
 # Removed temporary directory.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<FFmpeg::Command>,
L<File::Path>,
L<File::Spec::Functions>,
L<File::Temp>,
L<IO::CaptureOutput>,
L<Image::Random>,
L<Readonly>,
L<Video::Delay::Const>,
L<Video::Pattern>.

=head1 SEE ALSO

=over

=item L<Image::Random>

Perl class for creating random image.

=item L<Image::Select>

Selecting image from images directory.

=item L<Image::Select::Array>

Selecting image from list with checking.

=item L<Image::Select::Date>

Selecting image from images directory by date.

=item L<Video::Delay>

Perl classes for delays between frames generation.

=item L<Video::Pattern>

Video class for frame generation.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Video-Generator>.

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.07

=cut
