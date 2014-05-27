
#==============================================================================
# ** VLC Class
#--------------
#  The VLC instance spawning, disposing and management class.
#==============================================================================

require( 'posix/spawn' )

class VLC
  
  include( POSIX::Spawn )
  
  # 
  # Definition of local folders.
  PUBLIC_FOLDER = "/home/ib/ballin-meme/public"
  LOG_FOLDER    = "/home/ib/ballin-meme/log"
  TMP_FOLDER    = "/home/ib/ballin-meme/tmp"
  
  # Define the IP address as being the first interface's (eth0).
  IP_ADDRESS = `ifconfig`.match(/inet addr:(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})/)[1]
  ENCODER = %w( ffmpeg x264 )[1]
  
  WAIT_TIME = 1

  #-------------------------------------------------------------------------
  def initialize
    # -=-=-=-=-
    # Process IDs.
    @pid = Hash::new
    
    # -=-=-=-=-
    # Remove HLS files that might have survived.
    remove_hls_files
  end

  #-------------------------------------------------------------------------
  def spawn_process( method = 'hls', user = 'developer', pass = 'dev123', ip = '192.168.1.33' )
    ip =~ /(\d{1,3})$/
    key = $1.to_i
    
    if @pid[key].nil?
      url = "rtsp://#{user}:#{pass}@#{ip}:554/PSIA/streaming/channels/102"
      vlc = "cvlc #{url} --sout '#{hls_method( key )})}' & echo $!>#{TMP_FOLDER}/pid"
      sh  = spawn( vlc, in: '/dev/null', out: '/dev/null', err: "#{LOG_FOLDER}/camera#{key}.log" )

      # -=-=-=-=-
      # Have the VLC to properly execute before terminating the shell.
      sleep( WAIT_TIME )
      Process::detach( sh )
      
      @pid[key] = `cat #{TMP_FOLDER}/pid`.to_i
      puts "\t[!] Spawning VLC process ID: #{@pid[key]} for camera ##{key}..."
    else
      puts "\t[!] VLC process for camera ##{key} already exists!"
    end
  end
  
  #-------------------------------------------------------------------------
  def kill_process( pid = 0 )
    return if @pid.empty?
    
    # -=-=-=-=-
    # Terminating a single process
    unless pid.zero?
      fail IndexError unless @pid.value?( pid )
      
      puts "\t[!] Terminating process #{pid}..."
      Process::kill( 15, pid )
      
      sleep( WAIT_TIME )
      remove_hls_files( @pid.key( pid ) )

      @pid.delete( @pid.key( pid ) )
      puts "\t[!] Successful termination!"
    
    # -=-=-=-=-
    # Terminating all processes
    else
      @pid.each_value do | pid |
        puts "\t[!] Terminating process #{pid}..."
        Process::kill( 15, pid )
      end
      
      # -=-=-=-=-
      # Wait 1 second for processes to safely terminate.
      sleep( WAIT_TIME )
      remove_hls_files
      
      # -=-=-=-=-
      # Empty array of PIDs
      @pid.clear
      GC::start
    end
  rescue IndexError
    puts "\t[!] Error: process ID #{pid} does not exist."
  end
  
  #-------------------------------------------------------------------------
  def remove_hls_files( id = nil )
    puts "\n\t[!] Deleting HLS files..."
    Dir::glob( "#{PUBLIC_FOLDER}/live#{id}*" ).each do |file|
      puts "\t[!] Deleting #{file}..."
      File::delete( file )
    end
  end
  
  #-------------------------------------------------------------------------
  def hls_method( id, segs = 5, vcodec = 'mp4', brate = 256, fps = 32, w = 640, h = 480 )
    return "#std{ access=livehttp{ numsegs=#{segs}," +
           "index=#{PUBLIC_FOLDER}/live#{id}.m3u8," +
           "index-url=http://#{IP_ADDRESS}:3000/live#{id}-####.ts }," +
           "mux=ts{use-key-frames}, dst=#{PUBLIC_FOLDER}/live#{id}-####.ts }"

           #":transcode{ vcodec=#{vcodec}," +
           # "vb=#{brate}," +
           # "venc=#{ENCODER}," +
           # "fps=#{fps}," +
           # "width=#{w}," +
           # "height=#{h} }"
  end

  #-------------------------------------------------------------------------
  def rtsp_method( id )
    return "#rtp{ dst=#{IP_ADDRESS}, sdp=rtsp://#{IP_ADDRESS}:8080/live#{id}.sdp }"
  end

  #-------------------------------------------------------------------------
  def processes
    return @pid
  end
  
  #-------------------------------------------------------------------------
  def empty?
    return @pid.empty?
  end
  
  #-------------------------------------------------------------------------
  def process_intel
    return `ps -p #{@pid.values.join( ',' )}`
  end
end
