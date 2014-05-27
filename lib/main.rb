$:.unshift File.dirname __FILE__
require( 'vlc' )

begin
  unless ARGV.empty?
    ARGV.each do |arg|
      $debug if arg =~ /debug/i
    end
  end
  
  @vlc = VLC::new if @vlc.nil?

  loop do
    puts `clear`
    puts '=' * 32
    puts ' VLC HLS/RTSP Routing Script'
    puts '  s: Spawn VLC Process'
    puts '  k: Kill VLC Process'
    puts '  r: Running VLC Processes'
    puts '  h: Print process Hash'
    puts '  m: Input manual Ruby script'
    puts '  q: Exit (all VLC processes will be killed)'
    print "\n Desired action: "
    
    case gets.chomp
    when 's'
      puts '=' * 32
      
      #print ' Camera IP address: '
      #ip = gets.chomp
      
      #print ' Camera username: '
      #user = gets.chomp
      
      #print ' Camera password: '
      #pwd = gets.chomp

      #print ' Connection method (hls or rtsp): '
      #mtd = gets.chomp
      
      #unless ip.empty? and user.empty? and pwd.empty?
      #  @vlc.spawn_process( mtd, user, pwd, ip )
      #else
        #print ' Number of processes to spawn: '
        #gets.chomp.to_i.times { |i| @vlc.spawn_process( mtd = 'hls' ) }
      #end
      @vlc.spawn_process 'hls'
    when 'k'
      puts '=' * 32
      if @vlc.empty?
        puts ' No running processes.'
      else
        print ' Input process ID to SIGTERM (0 for all): '
        @vlc.kill_process( gets.chomp.to_i )
      end
    when 'r'
      puts '=' * 32
      if @vlc.empty?
        puts ' No running processes.'
      else
        puts ' Running processes:'
        puts @vlc.process_intel
      end
    when 'h'
      puts '=' * 32
      puts ' Hash of processses:'
      p @vlc.processes
    when 'm'
      puts '=' * 32
      puts ' Input Ruby script to evaluate:'
      print '> '
      eval gets.chomp
    when 'q', 'q!'
      break
    else
      puts ' No action exists for the inputted value!'
    end
    puts '(Press any key to return to menu.)'
    gets
  end
ensure
  @vlc.kill_process unless $_ == 'q!'
  puts "\nGoodbye!"
end
