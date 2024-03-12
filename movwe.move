module twitter::app {
    use std::error;
    use std::signer;
    use std::string;
    use std::vector;

    struct UserProfile has key {
        username: vector<u8>,
        bio: vector<u8>,
        tweets: vector<Tweet>
    }

    struct Tweet has store, drop {
        content: vector<u8>,
        timestamp: u64
    }

    public fun create_profile(account: &signer, username: vector<u8>, bio: vector<u8>): UserProfile {
        UserProfile {
            username,
            bio,
            tweets: vector::empty()
        }
    }

    public entry fun set_username(user: &mut UserProfile, new_username: vector<u8>) {
        user.username = new_username;
    }

    public entry fun edit_profile(user: &mut UserProfile, new_bio: vector<u8>) {
        user.bio = new_bio;
    }

    public fun get_user_profile(user: &UserProfile): (vector<u8>, vector<u8>) {
        (user.username, user.bio)
    }

    public entry fun create_tweet(user: &mut UserProfile, content: vector<u8>) {
        let tweet = Tweet {
            content,
            timestamp: std::unix_timestamp_now()
        };
        vector::push_back(&mut user.tweets, tweet);
    }

    public entry fun edit_tweet(user: &mut UserProfile, index: u64, new_content: vector<u8>) {
        let tweet = vector::borrow_mut(&mut user.tweets, index);
        tweet.content = new_content;
    }

    public fun get_tweet(user: &UserProfile, index: u64): (vector<u8>, u64) {
        let tweet = vector::borrow(&user.tweets, index);
        (tweet.content, tweet.timestamp)
    }

    public entry fun delete_tweet(user: &mut UserProfile, index: u64) {
        vector::remove(&mut user.tweets, index);
    }

    public entry fun delete_profile(user: &mut UserProfile) {
        let UserProfile { username: _, bio: _, tweets } = std::move_from<UserProfile>(user);
        vector::destroy_empty(tweets);
    }
}
