#!rspec

$LOAD_PATH.unshift "lib"

require "i2c"
require "i2c/driver/i2c-dev"
require "tempfile"

describe I2CDevice do
	before do
		@i2cout = ""
		@i2cin  = ""
		@ioctl  = nil

		ioctl = proc do |cmd, arg|
			@ioctl = [ cmd, arg ]
		end

		syswrite = proc do |str|
			@i2cout << str
		end

		sysread = proc do |n|
			@i2cin
		end

		@temp = Tempfile.new("i2c")
		file = nil
		open = File.method(:open)
		allow(File).to receive(:open) do
			file = open.call(@temp.path, "r+")
			file.define_singleton_method(:ioctl) {|cmd,arg| ioctl.call(cmd, arg) }
			file.define_singleton_method(:syswrite) {|str| syswrite.call(str) }
			file.define_singleton_method(:sysread) {|n| sysread.call(n) }
			file
		end

		@driver = I2CDevice::Driver::I2CDev.new(@temp.path)
	end

	describe "#i2cset" do
		it "should be write 1 byte" do
			i2c = I2CDevice.new(address: 0x10, driver: @driver)

			i2c.i2cset(0x00)

			expect(@ioctl).to eq([ I2CDevice::Driver::I2CDev::I2C_SLAVE, 0x10 ])
			expect(@i2cout).to eq("\x00")
		end

		it "should be write multi bytes" do
			i2c = I2CDevice.new(address: 0x10, driver: @driver)

			i2c.i2cset(0x00, 0x01, 0x02)

			expect(@ioctl).to eq([ I2CDevice::Driver::I2CDev::I2C_SLAVE, 0x10 ])
			expect(@i2cout).to eq("\x00\x01\x02")
		end
	end

	describe "#i2cget" do
		it "should be read 1 byte" do
			i2c = I2CDevice.new(address: 0x10, driver: @driver)

			@i2cin = "\x01"

			ret = i2c.i2cget(0x00)

			expect(ret).to eq("\x01")

			expect(@ioctl).to eq([ I2CDevice::Driver::I2CDev::I2C_SLAVE, 0x10 ])
			expect(@i2cout).to eq("\x00")
		end

		it "should be read multi byte" do
			i2c = I2CDevice.new(address: 0x10, driver: @driver)

			@i2cin = "\x01\x02\x03"

			ret = i2c.i2cget(0x00)

			expect(ret).to eq("\x01\x02\x03")

			expect(@ioctl).to eq([ I2CDevice::Driver::I2CDev::I2C_SLAVE, 0x10 ])
			expect(@i2cout).to eq("\x00")
		end
	end
end

