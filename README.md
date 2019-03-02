
# 1. Folder Structure
### Verilog folder

`MyDesign.v` shows the interfaces of your design
`ece564_project_tb_top.v` is the test fixture, also showing the interfaces expected.
`message.dat` is the message memory file that will get loaded.

```
message_eq_abc.dat, message_eq_hello.dat and messge_eq_message.dat are example messages that contain ascii characters for "abc", "Hello", and "Message" respectively.
```
### PythonScript folder
```
sha256verification.py is a script to generate the hash to check your design (if this crashes, try sha256verificationPython2.py)
```
## 2. To Run simulation

1) For a particular test, you will need to copy one of the message_eq... files to message.dat or create you own message.dat and then change the `define MSG_LENGTH = 5` in the testbench to the length of your message. Note the length is characters not bits.
2) Compile, run
`vlog -sv sram.v`
`vlog -sv MyDesign.v`
`vlog -sv ece564_project_tb_top.v`
`vsim -novopt tb_top`
3) Simulate 
`vsim  tb_top` 






