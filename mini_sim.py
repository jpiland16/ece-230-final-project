import re

CUSTOM_DEFINES = """
#define STATUS 0x03
#define W 0
#define F 1
"""

STATUS = 3
W = 0
F = 1

NON_EMPTY_LINE_RE = re.compile("^.*\w.*$")
DEFINE_RE = re.compile("#define\s(\w+)\s+(.*)")
INSTRUCTION_RE = re.compile("^\s+([a-zA_Z]+)\s*(.*)")

class PIC:

    class Register:

        def __init__(self, parent: 'PIC'):
            self.value = 0
            self.parent = parent

        def add_value(self, v):
            if v > 255:
                raise ValueError(f"{v} > 255, not allowed")
            ret = self.value + v
            self.parent.carry = int((ret & 256) != 0)
            ret = ret & 255
            return ret

        def rr(self):
            c_in = self.parent.carry
            self.parent.carry = self.value & 1
            return (self.value >> 1) + (c_in * 128)
            
        def rl(self):
            c_in = self.parent.carry
            self.parent.carry = int((self.value & 128) != 0)
            return ((self.value << 1) & 255) + (c_in * 1)

        def swap(self):
            return ((self.value >> 4) + ((self.value << 4) & 255))

    def __init__(self):

        self.carry = 0
        self.W = PIC.Register(self)
        self.GP_REGS = [PIC.Register(self) for i in range(16)]

    def eval_l(self, v):
        v = eval(v)
        while v < 0: 
            v = 256 + v
        return v

    def run_instructions(self, instructions, callback = lambda i: 0, 
        verbosely = []):

        skip_next = False
        counter = 0

        # 'movlw', 'swapf', 'clrf', 'addwf', 'rlf', 'btfsc', 'btfss', 'retlw', 'movwf', 'incf', 'andlw'
        for instruction, arguments in instructions:
            n = instruction.lower()
            a = [self.eval_l(l) for l in arguments]

            if skip_next:
                skip_next = False
                if len(verbosely) > 0: print("skip")
                continue

            if n == "movlw":
                self.W.value = a[0]

            elif n == "swapf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise ValueError("swapf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].swap()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "clrf":
                f = a[0]
                if f < 16:
                    raise ValueError("clrf for f < 16 not yet implemented")
                self.GP_REGS[f - 16].value = 0

            elif n == "addwf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise ValueError("addwf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].add_value(self.W.value)
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "rlf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise ValueError("rlf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].rl()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "rrf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise ValueError("rrf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].rr()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "incf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise ValueError("incf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].add_value(1)
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r
            
            elif n == "movwf":
                f = a[0]
                if f < 16:
                    raise ValueError("movwf for f < 16 not yet implemented")
                self.GP_REGS[f - 16].value = self.W.value

            elif n == "andlw":
                l = a[0]
                self.W.value = self.W.value & l

            elif n == "btfsc":
                f = a[0]
                b = a[1]
                v = 2 ** b
                if f == STATUS:
                    if b == 0:
                        if self.carry == 0:
                            skip_next = True
                    else:
                        raise ValueError(
                            f"read of status bit {b} not yet implemented")
                elif f < 16:
                    raise ValueError(f"read of f == {f} not yet implemented")
                if (self.GP_REGS[f - 16].value & v) == 0:
                    skip_next = True

            elif n == "btfss":
                f = a[0]
                b = a[1]
                v = 2 ** b
                if f == STATUS:
                    if b == 0:
                        if self.carry == 1:
                            skip_next = True
                    else:
                        raise ValueError(
                            f"read of status bit {b} not yet implemented")
                elif f < 16:
                    raise ValueError(f"read of f == {f} not yet implemented")
                if (self.GP_REGS[f - 16].value & v) != 0:
                    skip_next = True         

            elif n == "retlw":
                self.W.value = a[0]

            else:
                raise KeyError(f"instruction {n} not implemented!")

            callback(counter)
            counter += 1
            if len(verbosely) > 0:
                print(instruction, arguments)
                self.print_registers(verbosely)

    def print_registers(self, gp_regs = [], header = False, base = "hex", 
            vals = True):

        def format(v):
            if base == "bin":
                return f" {v:08b} "
            if base == "hex":
                return f"       {v:02X} "
            if base == "dec":
                return f" {v:8d} "
            raise KeyError(f"base {base} not recognized")


        if header:
            print(" W        | C " + "".join([f"| 0x{16 + i:02x}     " \
                for i in gp_regs]))
            print("----------|---" + "".join([f"|----------" for _ in gp_regs]))
        
        if not vals:
            return

        print(f"{format(self.W.value)}| {self.carry} " + "".join(
            [f"|{format(self.GP_REGS[i].value)}" for i in gp_regs]
        ))
        


def load_instructions(file_name, start_line, stop_line):

    file = open(file_name, "r").read()
    defines = [list(l) for l in DEFINE_RE.findall(CUSTOM_DEFINES + file)]

    for index, (mnemonic, replacement) in enumerate(defines):
        file = re.sub(f"\\b{mnemonic}\\b", replacement, file)
        for i in range(index, len(defines)):
            # Propagate change into the other define statements
            defines[i][1] = re.sub(
                f"\\b{mnemonic}\\b", replacement, defines[i][1])

    lines = file.splitlines()[start_line:stop_line]
    non_empty_lines = [l for l in lines if NON_EMPTY_LINE_RE.match(l)]
    instructions = [l.split(";")[0] for l in non_empty_lines]
    
    instructions_parsed = []
    
    for instruction in instructions:
        m = INSTRUCTION_RE.search(instruction)
        if m != None:
            ip = list(m.groups())
            ip[1] = ip[1].replace(" ", "").split(",")
            instructions_parsed.append(ip)

    return instructions_parsed

def run_test():
    instructions = load_instructions("main.asm", 152, 220)
    pic = PIC()
    gp = [0x0a, 0x0c, 0x0b]
    pic.GP_REGS[0x0a].value = 10
    pic.print_registers(gp_regs=gp, header=True, vals=False)
    pic.run_instructions(instructions, verbosely=gp)

def run_check():
    pic = PIC()
    pic.W.value = 0x14
    pic.W.add_value(0x41)
    print(pic.carry)

def main():
    run_test()
    # run_check()

if __name__ == "__main__":
    main()
