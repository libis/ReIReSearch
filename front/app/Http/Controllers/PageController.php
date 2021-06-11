<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class PageController extends Controller
{
    //
    public function __construct()
    {
    }

    public function help()
    {   

        $content = [
            'title' => "Help",
            'content' => "<p class=\"page subtitle1\">Search</p>
            <p class=\"page\">Simple search assumes that you are searching for any of the words you typed unless you type AND or NOT between words and phrases.</p>
            <p class=\"page\">AND assumes you are searching for results with all of the words included in your query. NOT assumes you are searching for results that do not include the words after NOT.</p>
            <p class=\"page\">Advanced search allows you to combine different search terms from different metadata fields.</p>
            <p class=\"page\">To start a new query, you can select ‘Clear’ under the search bar to clear your query.</p>

            <p class=\"page\">You can view the searches you have made during your current sessions by clicking the “Show saved queries” symbol (<i title=\"Show saved queries\" class=\"fa fa-list-ul\" style=\"font-size:1em;padding-left:0px\"></i>) at the bottom right of the search bar. If you are not logged in, this will only show the queries you have made in the current session (i.e. since you opened the site).</p>
            <p class=\"page\">You can search for records from a specific provider by using Advanced Search and selecting “Provider” in the first box. For an overview of data providers, consult the <a href=\"/page/about\">About</a> page.</p>
            <p class=\"page\">You can search for records from a particular collection by using Advanced Search and selecting “Dataset” in the first box. For an overview of available collections, consult the <a href=\"/page/about\">About</a> page.</p>
            <p class=\"page\">&nbsp;</p>
            <p class=\"page subtitle1\">Result page</p>
            <p class=\"page subtitle2\">Facets</p>
            <p class=\"page\">On the left hand side of the search result page, you can see all the facets with which you can filter your results. You can do this by either</p>
            <ul class=\"page\">
            <li>Clicking the word you want to use as a facet which will automatically filter out all the results this applies to</li>
            <li>Ticking the box next to the facet(s) you wish to filter with and select >> Apply filters </li>
            </ul>
            <p class=\"page\">The publication date is automatically set to a range with the oldest available record as starting date and the most recent as end date. If you adjust this, you will only get the records within that range.</p>
            <p class=\"page\">Under metadata provider, you can filter on the institutions that originally published the records.</p>
            <p class=\"page\">The facets ‘Contributor’, ‘Author’ and ‘Publisher show them ranked according to most frequently occurring in the search results. With queries that result in a large number of results, it is possible you only see the most frequently featured ones.</p>
            <p class=\"page\">The facet ‘Publication date of metadata’ shows when the records were imported into the ReIReS unified discovery environment.</p>
            
            <p class=\"page subtitle2\">Records</p>
            <p class=\"page\">Selecting a record brings you to its metadata page. This includes</p>
            <ul class=\"page\">
            <li>The relevant metadata</li>
            <li>Licensing information</li>
            <li>A link to the source record</li>
            <li>A link to the digital representation if available</li>
            <li>A citation tool</li>
            <li>The option to e-mail the record</li>
            <li>A persistent link to the record</li>
            </ul>
            <p class=\"page\">To view other records, you can close this window and select another record or scroll through the records one by one by clicking the arrow at the bottom.</p>
            <p class=\"page\">&nbsp;</p>

            <p class=\"page subtitle1\">Results from paid subscription databases</p>
            <p class=\"page\">For some subscription databases, some users will only see the number of occurrences:</p>
            <img src=\"/img/availableinsd.png\">
            <p class=\"page\">Users who work from within the IP range of an institution that has a running subscription on the database will enjoy full integration of results from this database in ReIReSearch.</p>
            <p class=\"page\">ReIReS-participants, ReIReS-trainers and private subscribers can find more information following the hyperlink to the publisher’s webpage. You can find the hyperlink by clicking on ‘subscription database’ in the box as shown above or by going to the <a href=\"/page/about\">About</a> page of ReIReSearch and finding the relevant provider there.</p>
            <p class=\"page\">Subscribers to the database who are within the proper IP range or who have a token will enjoy full integration of hits in the list of results, availability of all relevant facets and direct hyperlinks to the full record in the subscription database.</p>
            <p class=\"page\">Users who want to access a database with a token need to register for a free account to able to activate the token.</p>

            <p class=\"page\">&nbsp;</p>
            <p class=\"page subtitle1\">Registering and logging into your account</p>
            <p class=\"page\">You can create a free account by clicking “Register” at the top of the screen. The only information required is a name and e-mail address. Using ReIReSearch with your account gives access to extra functionalities.</p>            
            <p class=\"page\">You can log in to your account by clicking “Login” at the top of the page. Logging in allows you to save your queries, save records to a set and is required to access subscription databases with the use of a token</p>

            <p class=\"page\">&nbsp;</p>
            <p class=\"page subtitle1\">Functionalities for registered users</p>
            <p class=\"page\">Only the search history of your current session on ReIReSearch is saved automatically. If you want to save a query to be permanently available when you are logged in, you can click the “Save this query” symbol (<i title=\"Save this query\" class=\"fa fa-save\" style=\"font-size:1em;padding-left:0px\"></i>) at the bottom right of the search bar.</p>
            <p class=\"page\">You can view these queries by clicking the “Show saved queries” symbol (<i title=\"Show saved queries\" class=\"fa fa-list-ul\" style=\"font-size:1em;padding-left:0px\"></i>) at the bottom right of the search bar. You can delete these saved queries by clicking the symbol to the right of a query.</p>
            <p class=\"page\">As a registered user, you can also save a record to a set by clicking “Save to set” at the bottom right of the record view screen. To add multiple records to a set, you must first tick the box next to the record(s) on the search result page. To then save the selected records to a set, you can click the ‘Save selection in set’ symbol (<i title=\"Save selection in set\" class=\"fa fa-save\" style=\"font-size:1em;padding-left:0px\"></i>) at the top of the search result list (the ‘Save selection in set’ symbol will only appear after you have selected the first record).</p>
            <p class=\"page\">You can access your sets by selecting the “Show saved sets” symbol (<i title=\"Show saved sets\" class=\"fa fa-folder\" style=\"font-size:1em;padding-left:0px\"></i>) at the bottom right of the search bar.</p>
            <p class=\"page\">You can delete your profile by going to “Profile: [your name]” at the top of the page and selecting “Delete profile” at the bottom. The same page allows you to change your password by clicking “Change password”.</p>"
            ];
        return view('page', $content);

    }

    public function about()
    {   
        $content = [
            'title' => "About",
            'content' => 
            "
            <p class=\"page\">ReIReS is a starting community of twelve European institutions that are building a unique and highly qualified infrastructure on religious studies. ReIReS brings knowledge into the field of religious pluralism in Europe, thus contributing to a stable society. It explains and implements the idea that “Knowledge Creates Understanding”.</p>
            <p class=\"page\">One of the ambitions of ReIReS is to develop a platform where disparate digital resources and databases are searchable in a unified and standardized way. The ReIReS partner institutions house their own collections of manuscripts, documents and rare books and represent relevant collections of Christian, Jewish and Muslim works. To address the growing need of scholars to discover large sets of data such as these, ReIReS has designed ReIReSearch, a unified discovery environment for sources relevant to religious studies. Rather than consulting different collections separately and having to adjust their specific searches to the way these collections are indexed, you will be able to search them from one location using a single query.</p>
            <p class=\"page\">ReIReSearch offers an integrated access to the following collections:
            <table border=1 class=\"page\">
                <tr>
                    <td width=\"25%\">Data Provider</td>
                    <td width=\"25%\">Dataset</td>
                    <td width=\"50%\">About</td>
                </tr>
                <tr>
                    <td rowspan=\"2\"><a href=\"http://www.brepols.net/Pages/Home.aspx\" target=\"_blank\">Brepols Publishers</a></td>
                    <td><a name=\"DHGE\"></a><a href=\"https://about.brepolis.net/dictionnaire-dhistoire-et-de-geographie-ecclesiastiques/\" target=\"_blank\">Dictionnaire d’Histoire et de Géographie Ecclésiastiques</a></td>
                    <td>
                    The Dictionnaire d’histoire et de géographie ecclésiastiques (DHGE) is an unparalleled source of information for anyone interested in the history of the Church. The DHGE has a wide coverage, including all continents and the period spanning Antiquity to the present day. The Dictionnaire’s entries are divided into three distinct groups based on whether they deal with people, places or institutions.<br/>
                    The DHGE has been enriched with the biographies drawn from the collection Die Bischöfe des Heiligen Römischen Reiches (BHRR).
                    </td> 
                </tr>
                
                <tr>

                <td><a name=\"IR\"></a><a href=\"https://about.brepolis.net/index-religiosus/\" target=\"_blank\">Index Religiosus</a></td>
                <td>
                The Index Religiosus is an internationally renowned bibliography of academic publications in the fields of theology, religious sciences, and Church history. It is a gateway to books and articles written in major European languages (English, French, German, Italian, Spanish, Dutch, Portuguese, etc.). The bibliography stems from the fruitful collaboration between two institutions that are known for their expertise in the aforementioned domains – the KU Leuven and the Université Catholique de Louvain (UCL).<br/>
                The Index Religiosus brings together the Elenchus Bibliographicus (formerly published by the Ephemerides Theologicae Lovanienses) and the bibliography of the Revue d’Histoire Ecclésiastique. In combining and continuing these two bibliographies, the Index Religiosus is an indispensable instrument for scholars.<br/>
                Users who work from within the IP range of an institution that has a running subscription on the database will enjoy full integration of Index Religiosus in ReIReSearch.<br/>
                Other users involved in ReIReS or with a private subscription need to contact Brepols Publishers to request a token to access this database via ReIReSearch. This token can then be filled out under “Brepols user token” on the user profile page. For more information on how to activate access to Index Religiosus on ReIReSearch:<br/>
                <a href=\"https://about.brepolis.net/index-religiosus-for-reires-participants/\" target=\"_blank\">https://about.brepolis.net/index-religiosus-for-reires-participants/ </a> 
                </td>
            </tr>
                <tr>
                    <td colspan=\"3\">&nbsp;</td>
                </tr>
                <tr>
                    <td><a href=\"http://www.fscire.it/index.php/en/\" target=\"_blank\">Fondazione per le Scienze Religiose Giovanni XXIII</a></td>
                    <td><a name=\"Mansi\"></a><a href=\"http://mansi.fscire.it/\" target=\"_blank\">Mansi Digitale</a></td>
                    <td>The Mansi Digitale is a public digital database, which takes up the Amplissima collectio promoted by the Luccan Bishop Gian Domenico Mansi (1692-1769), in order to bring it up to date and to create, in dialogue with the specialists already identified for the printed edition COGD, a viable interface of inestimable value to the study of humanities. Thus Mansi Digitale or Mansi @mplissima aims at rendering available fundamental texts for European and world history, which are at present of difficult access and often limited to narrow specialized interests.</td>
                </tr>
                <tr>
                <td colspan=\"3\">&nbsp;</td>
                </tr>
                <tr>
                    <td><a href=\"https://bistummainz.de/kunst-gebaeude-geschichte/kirchengeschichte/index.html\" target=\"_blank\">Institut für Mainzer Kirchengeschichte</a></td>
                    <td><a name=\"KLERUS\"></a><a href=\"\" target=\"_blank\"></a>Klerus-Datenbank</td>
<!--                    <td>Basic biographical data of 7466 Roman Catholic clerics of the diocese of Mainz (Germany) in the 17th and 18th centuries including detailed information on their orders and their membership in religious institutes as well as on the source of information (mostly archival sources).</td> -->
                    <td>Basic biographical data of 7466 Roman Catholic clerics of the diocese of Mainz (Germany) from the 17th until the beginning of the 19th century including detailed information on their orders and their membership in religious institutes as well as on the source of information (mostly archival sources).<br />
                                            Further information on the cleric in particular can be requested from the Institute for Mainz Church History (<a href=\"mailto:kirchengeschichte@bistum-mainz.de\">kirchengeschichte@bistum-mainz.de</a>).</td>

                </tr>
                <tr>
                <td colspan=\"3\">&nbsp;</td>
                </tr>
                <tr>
                    <td><a href=\"https://www.blogs.uni-mainz.de/fb01-kt-mm-church-history/\" target=\"_blank\">Johannes Gutenberg-Universität Mainz</a></td>
                    <td><a name=\"JGUMAINZ\"></a><a href=\"https://gutenberg-capture.ub.uni-mainz.de/ubmzms/nav/classification/305106\" target=\"_blank\">Digitalisierte hebräische Handschriften aus der Jüdischen Bibliothek an der Johannes Gutenberg-Universität Mainz</a></td>
                    <td>Digitalised Hebrew manuscripts from 1700 until 1920. The Jewish Library at the JGU is a permanent loan of the Jewish Community of Mainz since 1955 and contains the remains of the libraries of the former Jewish Communities in Mainz, which were confiscated in 1938.</td>
                </tr>
                <tr>
                <td colspan=\"3\">&nbsp;</td>
                </tr>
                <tr>
                    <td rowspan=\"3\"><a href=\"https://www.kuleuven.be/english/\" target=\"_blank\">KU Leuven</a></td>
                    <td><a name=\"EastAsiaCollections\"></a><a href=\"https://bib.kuleuven.be/english/artes/East-Asia-collections\" target=\"_blank\">East Asia Collections</a></td>
                    <td>The East-Asian Library (LSIN) was inaugurated in the building of the University Library (Ladeuze square) in 1996. The university establishes here a collection about language, culture, religion and general social subjects from China, Japan and Korea.</td>
                </tr>
                <tr>
                    <td><a name=\"MauritsSabbe\"></a><a href=\"https://bib.kuleuven.be/english/msb\" target=\"_blank\">Maurits Sabbe Library</a></td>
                    <td>The Maurits Sabbe Library at the Faculty of Theology and Religious Studies (KU Leuven) is an internationally renowned research and heritage library in the domain of theology and religious studies. It boasts an extensive research collection of 1,3 million volumes. In addition to the modern works, the library has a collection of over 200 000 rare books, printed before 1800, and 1200 manuscripts. Its foci lie on Bibles, Bible commentaries, the Church Fathers, synodal documents, canon law and liturgical texts. The Maurits Sabbe Library also hosts a large collection of Jesuitica.</td>
                </tr>
                <tr>
                    <td><a name=\"BijCol\"></a><a href=\"https://bib.kuleuven.be/bijzondere-collecties/english/home\" target=\"_blank\">Special Collections</a></td>
                    <td>The department of Special Collections manages the rich library heritage that is preserved at the University Library. </td>
                </tr>
                <tr>
                <td colspan=\"3\">&nbsp;</td>
                </tr>
                <tr>
                    <td><a href=\"https://www.uni-sofia.bg/index.php/eng\" target=\"_blank\">Sofia University St. Kliment Ohridski</a></td>
                    <td><a name=\"Cyrillomethodiana\"></a><a href=\"https://cyrillomethodiana.uni-sofia.bg/component/booklibrary/69/all_category?Itemid=69\" target=\"_blank\">Cyrillomethodiana</a></td>
                    <td>A web-portal that includes a Virtual Library with downloadable electronic publications of books related to the fields of Slavic Studies and Religion.</td>
                </tr>
            </table>
            </p>
            "
        ];
        return view('page', $content);
    }

    public function tos()
    {   
        $content = [
            'title' => "Terms Of Service",
            'content' => "<p class=\"page subtitle1\">Using our Services</p>
            <p class=\"page\">You must follow any policies made available to you within the Services.</p>
            <p class=\"page\">Using our Services does not give you ownership of any intellectual property rights in our Services or the content you access.</p>
            <p class=\"page\">Our Services display content that does not belong to ReIReS. This content is the sole responsibility of the entity that makes it available.</p>
            
            <p class=\"page subtitle1\">Your account</p>
            <p class=\"page\">You may want to make an account to access some extra functions.</p>
            <p class=\"page\">To protect your account, keep your password confidential. You are responsible for the activity that happens on or through your account. Try not to reuse your password on third-party applications. If you learn of any unauthorized use of your password or account, follow these instructions.</p>
            
            <p class=\"page subtitle1\">Modifying and Terminating our Services</p>
            <p class=\"page\">We are constantly changing and improving our functions. We may add or remove functionalities or features, and we may suspend or stop a service altogether.</p>
            <p class=\"page\">You can stop using our platform at any time, although we’ll be sorry to see you go. ReIReS may also stop providing services to you, or add or create new limits to our Services at any time.</p>
            <p class=\"page\">We believe that you own your data and preserving your access to such data is important. If we discontinue a function, where reasonably possible, we will give you reasonable advance notice and a chance to get information out of that Service.</p>
            
            <p class=\"page subtitle1\">About these Terms</p>
            <p class=\"page\">We may modify these terms or any additional terms that apply to a service to, for example, reflect changes to the law or changes to our services.</p>
            "
        ];
        return view('page', $content);
    }

    public function subscriptions()
    {   
        $content = [
            'title' => "Subscription databases",
            'content' => "
                <p class=\"page\">Some of the resources available on ReIReSearch are part of paid subscription databases. For more information on how to access these records and benefit from the full integration, consult the relevant publisher’s webpage. For more information about this, consult the <a href=\"/page/help\">Help</a> page.</p>
                <p class=\"page\">The following subscription databases are currently integrated in ReIReSearch :</p>
                <p class=\"page\"><i>Index Religiosus (Brepols)</i>: <a href=\"https://about.brepolis.net/index-religiosus-for-reires-participants/\" target=\"_blank\">https://about.brepolis.net/index-religiosus-for-reires-participants/</a></p>

                <p>&nbsp;</p><p>&nbsp;</p>"];
        return view('page', $content);
    }

    public function privacy()
    {   
        $contactemail = "reires.helpdesk@libis.be";
        $content = [
            'title' => "Privacy Policy",
            'content' => "<p class=\"page subtitle1\">Summary</p>

            <p class=\"page\">We minimise the use of your data to the bare minimum. We only collect your name and e-mail address in case you register an account on this platform. We don’t share this information with Third Parties nor do we use it to contact you. We use cookies to analyse customer behaviour, administer the website, track users’ movements, and to collect information about users.</p>
            
            <p class=\"page subtitle1\">Definitions</p>
            
            <p class=\"page\">Personal Data – any information relating to an identified or identifiable natural person.</p>
            <p class=\"page\">Processing – any operation or set of operations which is performed on Personal Data or on sets of Personal Data.</p>
            <p class=\"page\">Data subject – a natural person whose Personal Data is being Processed.</p>
            
            <p class=\"page subtitle1\">Data Protection Principles</p>
            
            <p class=\"page\">We promise to follow the following data protection principles:</p>
            <ul class=\"page\">
            <li>Processing is lawful, fair, transparent. Our Processing activities have lawful grounds. We always consider your rights before Processing Personal Data. We will provide you information regarding Processing upon request.</li>
            <li>Processing is limited to the purpose. Our Processing activities fit the purpose for which Personal Data was gathered.</li>
            <li>Processing is done with minimal data. We only gather and Process the minimal amount of Personal Data required for any purpose.</li>
            <li>Processing is limited with a time period. We will not store your personal data for longer than needed.</li>
            <li>We will do our best to ensure the accuracy of data. </li>
            <li>We will do our best to ensure the integrity and confidentiality of data.</li>
            </ul>
            <p class=\"page subtitle1\">Data Subject’s Rights</p>
            
            <p class=\"page\">The Data Subject has the following rights:</p>
            <ol class=\"page\">
            <li>Right to information – meaning you have to right to know whether your Personal Data is being processed; what data is gathered, from where it is obtained and why and by whom it is processed.</li>
            <li>Right to access – meaning you have the right to access the data collected from/about you. This includes your right to request and obtain a copy of your Personal Data gathered.</li>
            <li>Right to rectification – meaning you have the right to request rectification or erasure of your Personal Data that is inaccurate or incomplete.</li>
            <li>Right to erasure – meaning in certain circumstances you can request for your Personal Data to be erased from our records.</li>
            <li>Right to restrict processing – meaning where certain conditions apply, you have the right to restrict the Processing of your Personal Data.</li>
            <li>Right to object to processing – meaning in certain cases you have the right to object to Processing of your Personal Data, for example in the case of direct marketing.</li>
            <li>Right to object to automated Processing – meaning you have the right to object to automated Processing, including profiling; and not to be subject to a decision based solely on automated Processing. This right you can exercise whenever there is an outcome of the profiling that produces legal effects concerning or significantly affecting you.</li>
            <li>Right to data portability – you have the right to obtain your Personal Data in a machine-readable format or if it is feasible, as a direct transfer from one Processor to another.</li>
            <li>Right to lodge a complaint – in the event that we refuse your request under the Rights of Access, we will provide you with a reason as to why. If you are not satisfied with the way your request has been handled please contact us.</li>
            <li>Right for the help of supervisory authority – meaning you have the right for the help of a supervisory authority and the right for other legal remedies such as claiming damages.</li>
            <li>Right to withdraw consent – you have the right withdraw any given consent for Processing of your Personal Data.</li>
            </ol>
            <a id=\"cookies\"></a><p class=\"page subtitle1\">Cookies and Other Technologies We Use</p>
            
            <p class=\"page\">We use cookies to analyse customer behaviour, administer the website, track users’ movements, and to collect information about users. This is done in order to personalise and enhance your experience with us, as well as measure web traffic to satisfy the requirements of our grant agreement.</p>
            
            <p class=\"page\">A cookie is a tiny text file stored on your computer. Cookies store information that is used to help make sites work. Only we can access the cookies created by our website. You can control your cookies at the browser level.</p>
            
            <p class=\"page\">We use cookies for the following purposes:</p>
            <ul class=\"page\">
            <li>Necessary cookies – these cookies are required for you to be able to use some important features on our website, such as logging in. These cookies don’t collect any personal information.</li>
            <li>Analytics cookies – these cookies are used to track the use and performance of our website and services.</li>
            </ul>
            <p class=\"page\">You can remove cookies stored in your computer via your browser settings. Alternatively, you can control some 3rd party cookies by using a privacy enhancement platform such as optout.aboutads.info or youronlinechoices.com. For more information about cookies, visit allaboutcookies.org. </p>
            
            <p class=\"page\">We use Google Analytics to measure traffic on our website. We anonymise your IP before it is received by Google. Google has its own Privacy Policy which you can review here. If you’d like to opt out of tracking by Google Analytics, visit the Google Analytics opt-out page.</p>
            
            <p class=\"page subtitle1\">Contact Information</p>
            
            <p class=\"page\">Contact us if you have any questions or problems regarding the use of your Personal Data and we will gladly assist you.</p>
            
            <p class=\"page\">Contact: <a href=\"mailto:\"". $contactemail . "\">". $contactemail . "</a></p><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br />"
        ];
        return view('page', $content);
    }    
}
