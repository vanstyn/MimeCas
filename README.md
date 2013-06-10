# MimeCas

RapidApp/Catalyst Demo application shown at YAPC::NA 2013

In progress... Please check back later for details

## What is MimeCas?

MimeCas is a simple DBIC schema/data-model for storing MIME objects. MIME objects are E-Mail messages, images, content parts and other types of attachments. The word "Cas" is in the name because it uses a Content-Addressed Storage design to store the MIME objects, similar to Git. In a CAS database the keys are checksums of content, which provides many intrensic benefets, such as automatic de-duplication, global namespaces and elimination of caching issues.

Individual MIME "Parts" are stored according to their SHA1 checksum. Multipart MIME objects contain referecnes to the SHA1s of their subparts, rather than the actual content. This creates a tree structure much like the structure of Git commits and tree (directory) objects.

If you are not familiar Git's wonderful design and Content-Addressed Storage concepts, I suggest you read my Linux Jounral Article on the topic: Git - Revision Control Perfected (2011)

In addition to the core MIME storage model, there is also a Mailbox/Folder/Message structure that provides a context for the objects.

This schema is just an example to showcase a DBIC schema that can be loaded with some nice test data (E-Mails). It has been loaded with "Mailboxes" referencing various mailing lists, with "Folders" representing Individual monthly Pipermail archive files containing "Messages"


