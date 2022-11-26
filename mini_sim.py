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
INSTRUCTION_RE = re.compile("^\s+([a-zA-Z]+)\s*(.*)")

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
            self.parent.digit_carry = int(((self.value & 15) + (v & 15)) > 15)
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

    def __init__(self, print_base = "hex", has_addlw = False):

        self.carry = 0
        self.digit_carry = 0
        self.W = PIC.Register(self)
        self.GP_REGS = [PIC.Register(self) for i in range(16)]
        self.print_base = print_base
        self.has_addlw = has_addlw

    def eval_l(self, v):
        v = eval(v)
        while v < 0: 
            v = 256 + v
        return v

    def run_instructions(self, instructions, callback = lambda i: 0, 
        verbosely = []):

        if len(verbosely) > 0:
            self.print_registers(verbosely, header=True, vals=False)

        skip_next = False
        counter = 0

        for instruction, arguments in instructions:
            n = instruction.lower()
            a = [self.eval_l(l) for l in arguments]

            if skip_next:
                skip_next = False
                if len(verbosely) > 0: 
                    print("SKIP", instruction, arguments)
                continue

            if n == "movlw":
                self.W.value = a[0]

            elif n == "swapf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise NotImplementedError(
                        "swapf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].swap()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "clrf":
                f = a[0]
                if f < 16:
                    raise NotImplementedError(
                        "clrf for f < 16 not yet implemented")
                self.GP_REGS[f - 16].value = 0

            elif n == "addwf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise NotImplementedError(
                        "addwf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].add_value(self.W.value)
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "rlf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise NotImplementedError(
                        "rlf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].rl()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "rrf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise NotImplementedError(
                        "rrf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].rr()
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r

            elif n == "incf":
                f = a[0]
                d = a[1]
                if f < 16:
                    raise NotImplementedError(
                        "incf for f < 16 not yet implemented")
                r = self.GP_REGS[f - 16].add_value(1)
                if d == F:
                    self.GP_REGS[f - 16].value = r
                else:
                    self.W.value = r
            
            elif n == "movwf":
                f = a[0]
                if f < 16:
                    raise NotImplementedError(
                        "movwf for f < 16 not yet implemented")
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
                    elif b == 1:
                        if self.digit_carry == 0:
                            skip_next = True
                    else:
                        raise NotImplementedError(
                            f"read of status bit {b} not yet implemented")
                elif f < 16:
                    raise NotImplementedError(
                        f"read of f == {f} not yet implemented")
                elif (self.GP_REGS[f - 16].value & v) == 0:
                    skip_next = True

            elif n == "btfss":
                f = a[0]
                b = a[1]
                v = 2 ** b
                if f == STATUS:
                    if b == 0:
                        if self.carry == 1:
                            skip_next = True
                    elif b == 1:
                        if self.digit_carry == 1:
                            skip_next = True
                    else:
                        raise NotImplementedError(
                            f"read of status bit {b} not yet implemented")
                elif f < 16:
                    raise NotImplementedError(f"read of f == {f} not yet implemented")
                elif (self.GP_REGS[f - 16].value & v) != 0:
                    skip_next = True         

            elif n == "retlw":
                self.W.value = a[0]

            elif n == "addlw":
                if self.has_addlw:
                    self.W.value = self.W.add_value(a[0])
                else:
                    raise NotImplementedError("family does not support ADDLW")

            else:
                raise NotImplementedError(f"instruction {n} not implemented!")

            callback(counter)
            counter += 1
            if len(verbosely) > 0:
                print(instruction, arguments)
                self.print_registers(verbosely)

    def print_registers(self, gp_regs = [], header = False, vals = True):

        def format(v):
            if self.print_base == "bin":
                return f" {v:08b} "
            if self.print_base == "hex":
                return f"       {v:02X} "
            if self.print_base == "dec":
                return f" {v:8d} "
            raise KeyError(f"base {self.print_base} not recognized")


        if header:
            print(" W        | C " + "".join([f"| 0x{16 + i:02x}     " \
                for i in gp_regs]))
            print("----------|---" + "".join([f"|----------" for _ in gp_regs]))
        
        if not vals:
            return

        print(f"{format(self.W.value)}| {self.carry} " + "".join(
            [f"|{format(self.GP_REGS[i].value)}" for i in gp_regs]
        ))
        


def load_instructions(file_name, start_line = None, stop_line = None):

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
    instructions = load_instructions("temp.asm")
    pic = PIC("hex", True)
    gp = [0x0a, 0x0c, 0x0b]
    pic.GP_REGS[0x0a].value = 10
    pic.run_instructions(instructions, verbosely=gp)
    # pic.print_registers(gp_regs=gp, header=True, vals=False); pic.print_registers(gp)

def test_all():
    instructions = load_instructions("main.asm", 152, 220)
    # instructions = load_instructions("temp.asm")
    correct_count = 0
    for i in range(256):
        pic = PIC(has_addlw=True)
        pic.GP_REGS[0x0a].value = i
        pic.run_instructions(instructions)
        result = \
            f"{pic.GP_REGS[0x0c].value:02X}{pic.GP_REGS[0x0b].value:02X}"[-3:]
        expected = f"{i:03d}"
        equal = expected == result
        # print(expected, result, "***" if not equal else "")
        if equal:
            correct_count += 1
    print(f"{correct_count} of 256 correct")

def run_check():
    pic = PIC()
    pic.W.value = 0x14
    pic.W.add_value(0x41)
    print(pic.carry)

def main():
    test_all()
    # run_test()
    # run_check()

if __name__ == "__main__":
    main()
