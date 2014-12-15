# ![Awesome](https://github.com/magicalpanda/magicalpanda.github.com/blob/master/images/awesome_logo_small.png?raw=true) MagicalRecord

[![Build Status](https://travis-ci.org/magicalpanda/MagicalRecord.svg?branch=develop)](https://travis-ci.org/magicalpanda/MagicalRecord)

In software engineering, the active record pattern is a design pattern found in software that stores its data in relational databases. It was named by Martin Fowler in his book Patterns of Enterprise Application Architecture. The interface to such an object would include functions such as Insert, Update, and Delete, plus properties that correspond more-or-less directly to the columns in the underlying database table.

>	Active record is an approach to accessing data in a database. A database table or view is wrapped into a class; thus an object instance is tied to a single row in the table. After creation of an object, a new row is added to the table upon save. Any object loaded gets its information from the database; when an object is updated, the corresponding row in the table is also updated. The	wrapper class implements accessor methods or properties for each column in the table or view.

>	*- [Wikipedia]("http://en.wikipedia.org/wiki/Active_record_pattern")*

MagicalRecord was inspired by the ease of Ruby on Rails' Active Record fetching. The goals of this code are:

* Clean up my Core Data related code
* Allow for clear, simple, one-line fetches
* Still allow the modification of the NSFetchRequest when request optimizations are needed

## Documentation

- [Installation](Docs/Installing-MagicalRecord.md)
- [Getting Started](Docs/Getting-Started.md)
- [Working with Managed Object Contexts](Docs/Working-with-Managed-Object-Contexts.md)
- [Creating Entities](Docs/Creating-Entities.md)
- [Deleting Entities](Docs/Deleting-Entities.md)
- [Fetching Entities](Docs/Fetching-Entities.md)
- [Saving Entities](Docs/Saving-Entities.md)
- [Usage Patterns](Docs/Usage-Patterns.md)
- [Importing Data](Docs/Importing-Data.md)
- [Logging](Docs/Logging.md)
* [Other Resources](Docs/Other-Resources.md)

## Support

MagicalRecord is provided as-is, free of charge. For support, you have a few choices:

- Ask your support question on [Stackoverflow.com](http://stackoverflow.com), and tag your question with **MagicalRecord**. The core team will be notified of your question only if you mark your question with this tag. The general Stack Overflow community is provided the opportunity to answer the question to help you faster, and to reap the reputation points. If the community is unable to answer, we'll try to step in and answer your question.
- If you believe you have found a bug in MagicalRecord, please submit a support ticket on the [Github Issues page for MagicalRecord](http://github.com/magicalpanda/magicalrecord/issues). We'll get to them as soon as we can. Please do **NOT** ask general questions on the issue tracker. Support questions will be closed unanswered.
- For more personal or immediate support, [MagicalPanda](http://magicalpanda.com/) is available for hire to consult on your project.


## Twitter

Follow [@MagicalRecord](http://twitter.com/magicalrecord) on twitter to stay up to date with the latest updates relating to MagicalRecord.
