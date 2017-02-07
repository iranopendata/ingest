# -*- coding: utf-8 -*-
import urllib2
import csv
from bs4 import BeautifulSoup
import os.path


def crawl_index(path):

    if not path:
        return False

    sublinks_file = open("sublinks.txt", "a+")
    contents = urllib2.urlopen("http://madreseha.ir%s" % path).read()
    soup = BeautifulSoup(contents, 'html.parser')

    target_table = soup.find_all("table", {"class": "ZLDNN_ArticleList"})

    if len(target_table):
        sub_links = target_table[0].find_all("a")

        for link in sub_links:
            if link.text:
                new_data = "%s::%s\n" % (link.attrs['href'], link.text)
                sublinks_file.write(new_data.encode('utf-8'))
                print(link.attrs['href'])
        sublinks_file.close()

url = "http://madreseha.ir/Default.aspx?tabid=82"

# Write page links to a local file to speed-up the process in next calls
if not os.path.isfile("links.txt"):
    main_page = urllib2.urlopen(url)

    main_page_content = main_page.read()

    soup = BeautifulSoup(main_page_content, 'html.parser')

    links = soup.find_all("a", {"class": "ZLDNN_TreeNode"})

    links_str = ""

    for link in links:
        links_str = "%s%s\n" % (links_str, link.attrs['href'])

    file = open("links.txt", "w+")
    file.write(links_str)
    file.close

if not os.path.isfile("sublinks.txt"):

    links_file = open("links.txt", "r")
    lines = links_file.read().split("\n")

    for line in lines:
        crawl_index(line)

if not os.path.isfile("initial-data.csv"):
    initial_csv_file = open("initial-data.csv", "w+")
    sublinks_file = open("sublinks.txt", "r")
    lines = sublinks_file.read().split("\n")

    loaded = []
    for line in lines:
        parts = line.split('::')
        if '-8-077-32-813-692-868-329-278-155.aspx' in parts[0]:
            continue
        if parts[0] in loaded:
            continue
        loaded.append(parts[0])
        contents = urllib2.urlopen(parts[0]).read()
        soup = BeautifulSoup(contents, 'html.parser')

        target_table = soup.find_all(
            "table", {"class": "MsoTableMediumGrid3Accent3"})

        if len(target_table):
            rows = target_table[0].find_all('tr')
            row_base = "\"%s\",\"%s\"" % (
                    parts[0], parts[1].replace("\"", "'"))
            for row in rows:

                try:
                    if 'mso-yfti-firstrow:yes' not in row.attrs['style']:
                        initial_csv_file.write(row_base)
                        tds = row.find_all('td')
                        for td in tds:
                            initial_csv_file.write(",\"%s\"" % td.text.replace(
                                "\"", "'").strip().encode("utf-8"))

                except KeyError:
                    print(row.attrs)
                    initial_csv_file.write(row_base)
                    tds = row.find_all('td')
                    for td in tds:
                        initial_csv_file.write(",\"%s\"" % td.text.replace(
                            "\"", "'").strip().encode("utf-8"))

                initial_csv_file.write("\n")

with open('initial-data.csv', 'rb') as csvfile:
    schools_file = open("schools.csv", "w+")
    csv_reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    schools_file.write("استان,نام مدرسه,مقطع تحصیلی,نوع,جنسیت,آدرس,تلفن,وب سایت\n")
    for row in csv_reader:
        if not len(row):
            continue

        province = ""
        level = ""
        gender = ""
        name = ""
        address = ""
        phone = ""
        site = ""
        school_type = ""

        if len(row) == 5:
            province = row[1].replace("مهدکودک و پیش دبستان استان", "").strip()
            level = "مهدکودک و پیش دبستان"
            name = row[2]
            address = row[3]
            phone = row[4]

        elif len(row) == 6:
            province = row[1].split("-")[0].replace("مدارس استان", "").strip()
            level = row[1].split("-")[2].replace("مدارس استان", "").strip()
            name = row[2]
            school_type = row[3]
            phone = row[4]
            site = row[5]

        elif len(row) == 7:
            row_parts = row[1].split('-')
            if len(row_parts) == 3:
                row[1] = '%s(%s)-%s' % (row_parts[0], row_parts[1], row_parts[2])
            parts = row[1].split('-')
            province = parts[0].replace("مدارس استان", "").strip()

            if 'پسرانه' in parts[1]:
                gender = 'پسرانه'
            elif 'دخترانه' in parts[1]:
                gender = 'دخترانه'

            level = parts[1].replace(gender, "").strip()
            if province == 'گلستان':
                gender = row[2]
                name = row[3]
                address = row[5]
                phone = row[6]
                school_type = row[4]
            else:
                name = row[2]
                school_type = row[3]
                address = row[4]
                phone = row[5]
                site = row[6]
        elif len(row) == 8:
            if 'سیستان' in row[1]:
                type_num = 4
            else:
                type_num = 5
            province = row[1].split('-')[0].replace("مدارس استان", "").strip()
            level = row[1].split('-')[1]
            gender = row[2]
            name = row[3]
            school_type = row[type_num]
            address = row[6]
            phone = row[7]
        if not name:
            continue
        schools_file.write(
            "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n" % (
                province, name, level, school_type,
                gender, address, phone, site))

    schools_file.close()
