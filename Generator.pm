package Video::Generator;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use IO::CaptureOutput qw(capture_exec);
use Image::Random;
use Video::Pattern;

# Version.
our $VERSION = 0.01;

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
	my ($self, $path) = @_;

	# Create images.
	$self->{'video_pattern'}->create($self->{'temp_dir'});

	# Create video.
	my $images_path = catfile($self->{'temp_dir'},
		'%03d.'.$self->{'image_type'});
	my $command = 'ffmpeg -loglevel error -nostdin -r '.$self->{'fps'}.
		' -i '.$images_path.' '.$path;
	my ($stdout, $stderr, $success, $exit_code)
		= capture_exec($command);
	if ($stderr) {
		my @stderr = split m/\n/ms, $stderr;
		err "Error with command '$command'.",
			map { ('STDERR', $_) } @stderr;
	}

	# Remove temporary directory.
	rmtree $self->{'temp_dir'};

	return;
}

1;

__END__
