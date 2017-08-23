#!/usr/bin/python3

"""Logging Module"""
import time
from email.mime.text import MIMEText
import smtplib
import os
import sys


class Log(object):
    """
        Attributes:
        file (file_obj)
        file_name (string)
    """

    def __init__(self, file_name, script_file=None):
        """Init Log object
           Args:
            file_name: dir/device/testname
            new_log (bool, optional): to append to previous log or not
        """
        super(Log, self).__init__()

        date = time.strftime("%d_%b_%Y")

        file_directory = file_name.split('/')[0]
        if not os.path.exists(file_directory):
            os.makedirs(file_directory)

        file_directory += "/" + file_name.split('/')[1]
        email_sujet = file_name.split('/')[1]
        if not os.path.exists(file_directory):
            os.makedirs(file_directory)

        file_directory += "/" + date
        email_sujet += "/" + date
        if not os.path.exists(file_directory):
            os.makedirs(file_directory)

        self.mail_sujet = email_sujet

        # self.file_name = file_directory+"/"+time.strftime("%H_%M")+ ".txt"
        self.file_name = file_directory + "/" + time.strftime("%I_%M_%p") + ".txt"
        self.file = open(self.file_name, "w")

        self.trap_fails = []

        self.fail_summary = []
        self.fail_count = []

        self.script_file = script_file

    def calc_statistics(self):
        self.separ(" ")
        self.separ(" ")
        self.separ(" ")
        self.test_name("Test Failure Summary")
        self.msg("\n\nList of Trap fails with time stamps")
        self.separ()
        self.msg("Total number of test fails: " + str(len(self.fail_summary)) + "\n")
        for x in self.fail_summary:
            self.msg(x + "\n")

        failCount = dict((x, self.trap_fails.count(x)) for x in set(self.trap_fails))

        self.separ()
        self.msg("\n\nTest Failure Stats:")
        self.separ()
        self.msg("\n")
        for x in sorted(failCount, key=failCount.get, reverse=True):
            # print x, failCount[x]
            self.fail_count.append(str(x) + "," + str(failCount[x]))
        #     self.msg(str(x)+ ","+ str(failCount[x]))
        # self.msg("\n")
        table = []
        for line in self.fail_count:
            table.append(line.split(","))

    def close(self, path=None):
        """Closes file for ever
        """

        self.calc_statistics()

        if path:
            self.append_script_to_log(path)
        elif self.script_file:
            self.append_script_to_log(self.script_file)

        self.file.close()

    def append_script_to_log(self, path):
        with open(path) as f:
            lines = f.readlines()
            # print lines
            for x in lines:
                self.msg(x, False, False)

    def temp_close(self):
        """Closes file
        """
        self.file.close()

    def open(self):
        """Reopens file
        """
        self.file = open(self.file_name, "a")

    def msg(self, string, newline=True, stdout=False):
        """Writes string to to log file
           Args:
            string (TYPE): desired message
            newline (bool, optional): flag to end msg with newline
        """
        # stdout = False
        string = str(string)
        if newline:
            self.file.write(string + "\n")
        else:
            self.file.write(string)

        if stdout:
            print(string)

    def separ(self, character="x"):
        """ add line charators to act as text separators """
        self.msg(character * 100, stdout=False)

    def test_name(self, name):
        """outputting a formatted test label to log file includes the full date
        """
        self.time(True)
        self.separ()
        self.msg(name.center(100))
        self.separ()

    def time(self, full=False):
        """output the time to file

        Args:
            full (bool, optional): include full date information

        Returns:
            date string
        """
        time_str = time.strftime(" %I:%M:%S %p")
        if full:
            self.msg(time.strftime("%A, %B %d") + "\t" * 18 + time_str)
        else:
            self.msg("\t" * 22 + time_str)
        return time_str

    def test_length(self, hrs, mins, secs):
        self.msg("Test will run for " + str(hrs) + ":" + str(mins) + ":" + str(secs))
        self.msg("Test will run for " + str(hrs) + " hours, " +
                 str(mins) + " minutes and " + str(secs) + " seconds")
        mins += 60 * hrs
        secs += mins * 60
        return secs

    def send_email(self, receivers, resultsFileName, subject):
        sender = 'automationHost@evertz.com'
        receiver_list = []
        print ("Results being emailed to:")
        for receiver in receivers.split(","):
            receiver_list.append(receiver)
            print (receiver)
        # print receiver_list
        f = open(resultsFileName, 'r')

        text = f.readlines()
        textlines = "Here is the automation log file which can also be found at " + \
            str(os.path.abspath(self.file_name)) + "\n"
        for line in text:
            textlines = textlines + line
        msg = MIMEText(textlines)

        msg['Subject'] = "Test Results for: " + str(subject)
        msg['From'] = 'automationHost@evertz.com'
        msg['To'] = receivers

        smtpObj = smtplib.SMTP('mail.burlington.evertz.tv')
        smtpObj.sendmail(sender, receiver_list, msg.as_string())
        smtpObj.quit()

    def email_results(self, address):
        self.send_email(address, self.file_name, self.mail_sujet)


from random import randint


def main():
    log = Log("beta_logs/log/stat_test")
    log.test_name("Stats ftw")

    for x in xrange(1, 25):
        num = (randint(1, 10))
        log.trap_fails.append("Video Loss detected for channel " + str(num) + " of the VIP")
        log.fail_summary.append("Video Loss detected for channel " + str(num) +
                                " of the VIP" + time.strftime(" %I:%M:%S %p"))

    log.close()
    log.email_results("amo@evertz.com")


def pause(secs):
    print ("Pausing for " + str(secs) + " seconds").center(75)
    for x in xrange(secs, 0, -1):
        # print '{0}s left\r'.format(x),
        print ('{: ^75}\r'.format(str(x) + 's left')),
        time.sleep(1)
    print ("")
    return ("Pausing for " + str(secs) + " seconds").center(75)


if __name__ == '__main__':
    main()
