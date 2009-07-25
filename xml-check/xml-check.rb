#!/usr/local/bin/ruby

# pre-commit フックから呼ぶための、xmlチェックツール

require 'nkf'
require 'win32ole'
require 'logger'
require 'tempfile'

$KCODE = 'UTF8'
ENV['LANG'] = 'ja_JP.UTF-8'

# Constants
REPOS=ARGV[0]
TXN=ARGV[1]

$log = Logger.new("#{REPOS}/xml-check.log", 3)
$log.level = Logger::DEBUG

def check_xml(xmlPath)
  doc = WIN32OLE.new('Msxml2.DOMDocument')
  doc.async = false
  if !doc.load(xmlPath)
    $stderr.puts('Oops! XML may not be well-formed.')
    $log.debug(' ==> Oops! XML may not be well-formed.')
    exit 1
  else
    $log.debug(' ==> OK. XML load was succeeded.')
  end
end


$log.debug('script called')

svnchanged = NKF.nkf('--utf8', %x{svnlook changed -t #{TXN} #{REPOS}}.chomp!)

svnchanged.each { |line|
  if (/U.+¥s(.+xml)$/ =~ line)
    tf = Tempfile.new('xml-check')
    $log.debug("check #{$1}")
    IO.foreach("|svnlook cat -t #{TXN} #{REPOS} #{$1}", "r+") { |line|
      tf.write line
    }
    tf.close
    check_xml(tf.path)
  end
}

exit 0
