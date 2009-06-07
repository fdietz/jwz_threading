class JWZThreading
  module VERSION
    unless defined? MAJOR
      MAJOR = 0
      MINOR = 3
      TINY  = 0

      STRING = [MAJOR, MINOR, TINY].join('.')

      SUMMARY = "jwz_threading version #{STRING}"
    end
  end
end