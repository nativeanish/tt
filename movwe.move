module twitter::twitter {
    use std::vector;
    use std::string;
    use std::option;

    // Struct to represent a user profile
    struct Profile has key, store {
        id: u64,
        username: vector<u8>,
        email: vector<u8>,
        bio: vector<u8>,
        created_at: u64,
    }

    // Struct to represent a tweet
    struct Tweet has key, store {
        id: u64,
        user_id: u64,
        content: vector<u8>,
        created_at: u64,
        edited_at: option::Option<u64>,
        likes: vector<u64>,
        retweet_count: u64,
    }

    // Global storage for profiles and tweets
    vector<Profile> profiles;
    vector<Tweet> tweets;

    // Function to create a new user profile
    public fun create_profile(username: vector<u8>, email: vector<u8>, bio: vector<u8>, created_at: u64): option::Option<u64> {
        let user_exists = vector::contains(&profiles, &Profile {
            id: 0,
            username: username,
            email: email,
            bio: bio,
            created_at: 0,
        });

        if (user_exists) {
            return option::none()
        };

        let user_id = (vector::length(&profiles) as u64) + 1;
        let new_profile = Profile {
            id: user_id,
            username,
            email,
            bio,
            created_at,
        };

        vector::push_back(&mut profiles, new_profile);
        option::some(user_id)
    }

    // Function to authenticate a user
    public fun authenticate_user(username: vector<u8>, email: vector<u8>): option::Option<u64> {
        let user = vector::borrow(&profiles, 0);
        while (option::is_some(user)) {
            let Profile { id, username: u, email: e, bio: _, created_at: _ } = option::extract(user);
            if (string::equal_lossless(&u, &username) && string::equal_lossless(&e, &email)) {
                return option::some(id)
            };
            user = vector::borrow(&profiles, (id as u64));
        };
        option::none()
    }

    // Function to create a new tweet
    public fun create_tweet(user_id: u64, content: vector<u8>, created_at: u64): option::Option<u64> {
        let user_exists = vector::contains(&profiles, &Profile {
            id: user_id,
            username: vector::empty(),
            email: vector::empty(),
            bio: vector::empty(),
            created_at: 0,
        });

        if (!user_exists) {
            return option::none()
        };

        let tweet_id = (vector::length(&tweets) as u64) + 1;
        let new_tweet = Tweet {
            id: tweet_id,
            user_id,
            content,
            created_at,
            edited_at: option::none(),
            likes: vector::empty(),
            retweet_count: 0,
        };

        vector::push_back(&mut tweets, new_tweet);
        option::some(tweet_id)
    }

    // Function to edit a tweet
    public fun edit_tweet(tweet_id: u64, user_id: u64, content: vector<u8>, edited_at: u64): bool {
        let tweet = vector::borrow_mut(&mut tweets, (tweet_id - 1) as u64);
        if (option::is_some(tweet)) {
            let Tweet { user_id: tweet_user_id, content: _, edited_at: _, likes: _, retweet_count: _ } = option::extract(tweet);
            if (tweet_user_id == user_id) {
                vector::push_back(&mut tweets, Tweet {
                    id: tweet_id,
                    user_id,
                    content,
                    created_at: vector::borrow(&tweets, (tweet_id - 1) as u64).created_at,
                    edited_at: option::some(edited_at),
                    likes: vector::empty(),
                    retweet_count: 0,
                });
                return true
            };
        };
        false
    }

    // Function to delete a tweet
    public fun delete_tweet(tweet_id: u64, user_id: u64): bool {
        let tweet = vector::borrow(&tweets, (tweet_id - 1) as u64);
        if (option::is_some(tweet)) {
            let Tweet { user_id: tweet_user_id, content: _, created_at: _, edited_at: _, likes: _, retweet_count: _ } = option::extract(tweet);
            if (tweet_user_id == user_id) {
                vector::remove(&mut tweets, (tweet_id - 1) as u64);
                return true
            };
        };
        false
    }

    // Function to like a tweet
    public fun like_tweet(tweet_id: u64, user_id: u64): bool {
        let tweet = vector::borrow_mut(&mut tweets, (tweet_id - 1) as u64);
        if (option::is_some(tweet)) {
            let Tweet { user_id: _, content: _, created_at: _, edited_at: _, likes, retweet_count: _ } = option::extract(tweet);
            if (!vector::contains(&likes, &user_id)) {
                vector::push_back(&mut likes, user_id);
                vector::push_back(&mut tweets, Tweet {
                    id: tweet_id,
                    user_id: vector::borrow(&tweets, (tweet_id - 1) as u64).user_id,
                    content: vector::borrow(&tweets, (tweet_id - 1) as u64).content,
                    created_at: vector::borrow(&tweets, (tweet_id - 1) as u64).created_at,
                    edited_at: vector::borrow(&tweets, (tweet_id - 1) as u64).edited_at,
                    likes,
                    retweet_count: 0,
                });
                return true
            };
        };
        false
    }

    // Function to retweet a tweet
    public fun retweet(tweet_id: u64, user_id: u64, created_at: u64): option::Option<u64> {
        let original_tweet = vector::borrow(&tweets, (tweet_id - 1) as u64);
        if (option::is_some(original_tweet)) {
            let Tweet { user_id: _, content, created_at: _, edited_at: _, likes: _, retweet_count: _ } = option::extract(original_tweet);
            let retweet_id = create_tweet(user_id, content, created_at);
            if (option::is_some(&retweet_id)) {
                let retweet_index = option::extract(&mut retweet_id) - 1;
                vector::push_back(&mut tweets, Tweet {
                    id: vector::borrow(&tweets, retweet_index as u64).id,
                    user_id: vector::borrow(&tweets, retweet_index as u64).user_id,
                    content: vector::borrow(&tweets, retweet_index as u64).content,
                    created_at: vector::borrow(&tweets, retweet_index as u64).created_at,
                    edited_at: vector::borrow(&tweets, retweet_index as u64).edited_at,
                    likes: vector::empty(),
                    retweet_count: 1,
                });
                return option::some(vector::borrow(&tweets, retweet_index as u64).id)
            };
        };
        option::none()
    }

    // Function to delete a user account
    public fun delete_account(user_id: u64) {
        let user_index = vector::find(&mut profiles, &Profile {
            id: user_id,
            username: vector::empty(),
            email: vector::empty(),
            bio: vector::empty(),
            created_at: 0,
        });
        if (option::is_some(&user_index)) {
            vector::remove(&mut profiles, option::extract(&mut user_index));
        };

        let i = 0;
        while (i < vector::length(&tweets)) {
            let tweet = vector::borrow(&tweets, i);
            if (option::is_some(tweet)) {
                let Tweet { user_id: tweet_user_id, content: _, created_at: _, edited_at: _, likes: _, retweet_count: _ } = option::extract(tweet);
                if (tweet_user_id == user_id) {
                    vector::remove(&mut tweets, i);
                } else {
                    i = i + 1;
                };
            } else {
                i = i + 1;
            };
        };
    }
}
